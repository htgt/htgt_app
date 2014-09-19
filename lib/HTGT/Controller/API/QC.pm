package HTGT::Controller::API::QC;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST' }

use Try::Tiny;
use HTGT::QC::Config;
use HTGT::QC::Run;
use HTGT::QC::Util::SubmitQCFarmJob::Vector;
use HTGT::QC::Util::SubmitQCFarmJob::ESCell;
use HTGT::QC::Util::ListTraceProjects;

sub submit_lims2_qc :Path('/api/submit_lims2_qc') {

    my ( $self, $c ) = @_;

    my $qc_data = $c->req->data;

    die "Invalid username/password"
        unless $self->_authenticate_user( $c, $qc_data->{ username }, $qc_data->{ password } );

    if ( $qc_data->{ run_type } eq 'es_cell' ) {
        my $epd_plate_name = shift $qc_data->{ sequencing_projects };
        $c->log->debug( "Retrieving sequencing projects for epd plate $epd_plate_name" );

        my @all_projects = $self->_get_trace_projects( $epd_plate_name );

        die "Couldn't find any sequencing projects for $epd_plate_name"
            unless @all_projects;

        $c->log->debug( "Found the following sequencing projects: " . join ", ", @all_projects );

        $qc_data->{ sequencing_projects } = \@all_projects;
    }

    # Attempt to validate input and launch QC job
    try {
        $self->_validate_params( $qc_data );

        my $config = HTGT::QC::Config->new( { is_lims2 => 1 } );

        my %run_params = (
            config              => $config,
            profile             => $qc_data->{ profile },
            template_plate      => $qc_data->{ template_plate },
            sequencing_projects => $qc_data->{ sequencing_projects },
            run_type            => $qc_data->{ run_type },
            created_by          => $qc_data->{ created_by },
            species             => $qc_data->{ species },
            persist             => 1,
        );

        my %run_types = (
            es_cell   => "ESCell",
            vector    => "Vector",
        );

        die $qc_data->{ run_type } . " is not a valid run type."
            unless exists $run_types{ $qc_data->{ run_type } };

        my $submit_qc_farm_job = "HTGT::QC::Util::SubmitQCFarmJob::" . $run_types{ $qc_data->{ run_type } };

        #add any additional type specific modifications in this if
        if ( $qc_data->{ run_type } eq "vector" ) {
            #only vector needs a plate_map.
            $run_params{ plate_map } = $qc_data->{ plate_map };
        }


        my $run = HTGT::QC::Run->init( %run_params );
        my $run_id = $run->id or die "No QC run ID generated"; #this is pretty pointless; we always get one.

        $submit_qc_farm_job->new( { qc_run => $run } )->run_qc_on_farm();

        $self->status_ok(
            $c,
            entity => { qc_run_id => $run_id, }
        );
    }
    catch {
        $c->log->warn( $_ );
        $self->status_bad_request(
            $c,
            message => UNIVERSAL::isa( $_, 'Throwable::Error' ) ? $_->message : $_,
        );
    };
}

sub kill_lims2_qc :Path('/api/kill_lims2_qc') {
    my ( $self, $c ) = @_;

    my $qc_data = $c->req->data;

    #make sure the user has a valid login and is on campus
    return unless $self->_authenticate_user( $c, $qc_data->{ username }, $qc_data->{ password } );

    my $config = HTGT::QC::Config->new( { is_lims2 => 1 } );

    #vms have a separate qc.conf but they SHOULD be in sync

    try {
        die "You must provide a QC run id.\n" unless $qc_data->{ qc_run_id };

        my $config = HTGT::QC::Config->new( { is_lims2 => 1 } );
        my $kill_jobs = HTGT::QC::Util::KillQCFarmJobs->new(
            {
                qc_run_id => $qc_data->{ qc_run_id },
                config    => $config,
            } );

        my $jobs_killed = $kill_jobs->kill_unfinished_farm_jobs();
        $self->status_ok(
            $c,
            entity => { job_ids => $jobs_killed },
        );
    }
    catch {
        print "$_\n";
        $self->status_bad_request(
            $c,
            message => UNIVERSAL::isa( $_, 'Throwable::Error' ) ? $_->message : $_,
        );
    };
}

sub badger_seq_projects :Path('/api/badger_seq_projects') {
	my ($self, $c ) = @_;

	my $data = $c->req->data;

	return unless $self->_authenticate_user( $c, $data->{ username }, $data->{ password } );

	my $term = $data->{term};

	try {
	    my $projects = $c->model('BadgerRepository')->search( $term );
        $self->status_ok(
            $c,
            entity => { badger_seq_projects => $projects },
        );
	}
	catch {
		# Just return empty list if there was a problem with the BadgerRepository query
		$self->status_ok(
		    $c,
		    entity => { badger_seq_projects => [] },
		);
	};
}

sub _authenticate_user {
    my ( $self, $c, $user, $pass ) = @_;

    # user must authenticate and be on campus
    my $authenticated = $c->authenticate(
        { username => $user, password => $pass, },
        'qc'
    );

    unless ( $authenticated ) {
        $self->status_bad_request(
            $c,
            message => "Invalid username and password provided for QC job submission",
        );
        return 0;
    }

    my $user_ip = $c->req->address;
    unless ( $user_ip =~ /^172\.17\./ ) {
        my $message = "Unauthorized IP address: $user_ip. "
                     ."QC submissions can only by made from internal Sanger IP addresses.";

        # This should be a status_forbidden but it throws error
        # Can't locate object method "status_forbidden" via package "HTGT::Controller::API::QC"
        $self->status_bad_request( $c, message => $message, );
        return 0;
    }

    return 1;
}

sub _validate_params {
    my ( $self, $params ) = @_;

    die "You must provide a 'profile'\n"
        unless $params->{ profile } =~ /\w+/;

    die "You must provide a 'template_plate'\n"
        unless $params->{ template_plate } =~ /\w+/;

    die "You must provide one or more 'sequencing_projects'\n"
        unless $params->{ sequencing_projects } and ref $params->{ sequencing_projects } eq 'ARRAY';

    #if we are provided a plate_map (it's optional) make sure its a hash
    die "The plate_map must be a HashRef\n"
        if $params->{ plate_map } and ref $params->{ plate_map } ne 'HASH';

    return $params;
}

sub _get_trace_projects {
    my ( $self, $epd_plate_name ) = @_;
    return @{ HTGT::QC::Util::ListTraceProjects->new()->get_trace_projects( $epd_plate_name ) };
}


1;
