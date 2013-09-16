#!/usr/bin/env perl

=head1 SYNOPSIS

	reload_qc_data_onto_384_well_plate.pl --plate_name PG00223_Z_1 --run_id 24534 [--commit]

=cut

{

    package Reload::QCData::Onto::384Plate;
    use Data::Dumper::Concise;
    use HTGT::DBFactory;
    use Log::Log4perl ':easy';
    use Moose;
    BEGIN { Log::Log4perl->easy_init }
    with qw( MooseX::Getopt MooseX::Log::Log4perl::Easy );
    has plate_name => (
        isa      => 'Str',
        is       => 'ro',
        required => 1,
    );
    has run_id => (
        isa      => 'Int',
        is       => 'ro',
        required => 1,
    );
    has commit => (
        isa     => 'Bool',
        is      => 'ro',
        default => 0,
    );
    has _eucomm_vector => (
        lazy_build => 1,
        reader     => 'eucomm_vector',
        handles    => { plate_rs => [ resultset => 'HTGTDB::Plate' ], },
    );
    sub _build__eucomm_vector { HTGT::DBFactory->connect('eucomm_vector') }
    has _vector_qc => (
        lazy_build => 1,
        reader     => 'qc_schema',
        handles =>
            { result_rs => [ resultset => 'ConstructQC::QctestResult' ] }
    );
    sub _build__vector_qc { HTGT::DBFactory->connect('vector_qc') }

    sub BUILD {
        my $self = shift;

        $self->log_info( 'attempting to reload qc run for plate ['
                . $self->plate_name
                . ']' );

        if ( $self->plate_name =~ m/^(\w+)_\d$/ ) {
            $self->log_info("searching for plates matching '$1%'");

            my $plate_rs
                = $self->plate_rs->search_rs( { name => { like => "$1%" } } );
            $self->log_info(
                'found ' . $plate_rs->count . ' plates in HTGTDB' );

            my $result_rs = $self->result_rs->search_rs(
                {   "qctestRun.qctest_run_id"         => $self->run_id,
                    "me.is_best_for_construct_in_run" => 1,
                },
                { join => ["qctestRun"], prefetch => ['constructClone'] }
            );

            unless ( $result_rs->count > 0 ) {
                confess 'Unable to find a QC Test Run for the given ID ['
                    . $self->run_id . ']';
            }

            $self->log_info( 'found '
                    . $result_rs->count
                    . ' results for run ['
                    . $self->run_id
                    . ']' );

            $self->eucomm_vector->txn_do(
                sub {
                    while ( my $plate = $plate_rs->next ) {
                        my %qc_options = (
                            qc_schema        => $self->qc_schema,
                            qctest_run_id    => $self->run_id,
                            user             => $ENV{USER},
                            override         => 1,
                            ignore_well_slop => 1,
                        );
                        $self->log_info(
                            'loading qc for plate [' . $plate->name . ']' );
                        $plate->load_384well_qc( \%qc_options );
                    }
                    unless ( $self->commit ) {
                        $self->log_info('Rolling back');
                        $self->eucomm_vector->txn_rollback();
                    }
                }
            );
        }
    }
}

Reload::QCData::Onto::384Plate->new_with_options();
