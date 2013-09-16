package HTGT::Utils::AlleleNameUpdater::CLI;

use Moose;
use Log::Log4perl ':levels';
use HTGT::DBFactory;
use HTGT::Utils::Tarmits;
use HTGT::Utils::FileDownloader;
use Try::Tiny;
use Data::Dump 'pp';
use Const::Fast;
use namespace::autoclean;

const my $CURRENT_HTGT_DATA_QUERY => <<'EOT';
select well.well_name as clone_name, well.well_id, well_data.data_value as allele_name
from plate
join well on well.plate_id = plate.plate_id
left outer join well_data on well_data.well_id = well.well_id and well_data.data_type = 'allele_name'
where plate.type = 'EPD'
EOT

const my $CURRENT_TARG_REP_DATA_QUERY => <<'EOT';
select
        a.id as allele_id,
        e.id as es_cell_id,
        e.name as clone_name,
        e.mgi_allele_id,
        e.mgi_allele_symbol_superscript allele_symbol_superscript,
        e.allele_symbol_superscript_template
from
        targ_rep_pipelines p
        join targ_rep_es_cells e on e.pipeline_id = p.id
        join targ_rep_alleles a on e.allele_id = a.id

where
        p.name in ('KOMP-CSD','EUCOMM','EUCOMMTools');
EOT

with qw( MooseX::Getopt MooseX::Log::Log4perl );

has debug => (
    isa     => 'Bool',
    is      => 'ro',
    traits  => [ 'Getopt' ],
    default => 0
);

has verbose => (
    isa     => 'Bool',
    is      => 'ro',
    traits  => [ 'Getopt' ],
    default => 0
);

has log_layout => (
    isa     => 'Str',
    is      => 'ro',
    traits  => [ 'Getopt' ],
    default => '%p %m%n'
);

has want_update_targrep => (
    isa      => 'Bool',
    is       => 'ro',
    traits   => [ 'Getopt' ],
    cmd_flag => 'update-targrep',
    default  => 1
);

has want_update_htgt => (
    isa      => 'Bool',
    is       => 'ro',
    traits   => [ 'Getopt' ],
    cmd_flag => 'update-htgt',
    default  => 1
);

has commit => (
    isa     => 'Bool',
    is      => 'ro',
    traits  => [ 'Getopt' ],
    default => 0
);

has komp_allele_report_url => (
    isa      => 'Str',
    is       => 'ro',
    traits   => [ 'Getopt' ],
    cmd_flag => 'komp-allele-report-url',
    default  => 'ftp://ftp.informatics.jax.org/pub/reports/KOMP_Allele.rpt'
);

has eucomm_allele_report_url => (
    isa      => 'Str',
    is       => 'ro',
    traits   => [ 'Getopt' ],
    cmd_flag => 'eucomm-allele-report-url',
    default  => 'ftp://ftp.informatics.jax.org/pub/reports/EUCOMM_Allele.rpt'
);

has edit_user => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    cmd_flag => 'edit-user',
    default  => $ENV{USER}
);

has idcc_dbh => (
    isa        => 'DBI::db',
    is         => 'ro',
    traits     => [ 'NoGetopt' ],
    default    => sub { HTGT::DBFactory->dbi_connect( 'tarmits' ) }
);

has htgt_schema => (
    isa        => 'HTGTDB',
    is         => 'ro',
    traits     => [ 'NoGetopt' ],
    default    => sub { HTGT::DBFactory->connect( 'eucomm_vector' ) }
);

has idcc_targ_rep => (
    is         => 'ro',
    isa        => 'HTGT::Utils::Tarmits',
    traits     => [ 'NoGetopt' ],
    default    => sub { HTGT::Utils::Tarmits->new_with_config() }
);

has err_exit => (
    is        => 'ro',
    isa       => 'Bool',
    traits    => [ 'NoGetopt', 'Bool' ],
    handles   => {
        set_err_exit => 'set'
    },
    init_arg  => undef,
    default   => 0
);

sub BUILD {
    my $self = shift;

    my $log_level = $self->debug   ? $DEBUG
                  : $self->verbose ? $INFO
                  :                  $WARN;

    Log::Log4perl->easy_init(
        {
            layout => $self->log_layout,
            level  => $log_level
        }
    );

    die "At least one of --update-targ-rep or --update-htgt must be specified\n"
        unless $self->want_update_targrep or $self->want_update_htgt;

    die "At least one of --komp-allele-report-url or --eucomm-allele-report-url must be specified\n"
        unless $self->komp_allele_report_url or $self->eucomm_allele_report_url;
}

has allele_name_for => (
    isa        => 'HashRef[Str]',
    traits     => [ 'NoGetopt', 'Hash' ],
    init_arg   => undef,
    handles    => {
        set_allele_name    => 'set',
        get_allele_name    => 'get',
        allele_clone_names => 'keys',
    },
    default    => sub { {} }
);

has allele_superscript_for => (
    isa        => 'HashRef[Str]',
    traits     => [ 'NoGetopt', 'Hash' ],
    init_arg   => undef,
    handles    => {
        set_allele_superscript => 'set',
        get_allele_superscript => 'get',
    },
    default    => sub { {} }
);

has mgi_allele_id_for => (
    isa        => 'HashRef[Str]',
    traits     => [ 'NoGetopt', 'Hash' ],
    init_arg   => undef,
    handles    => {
        set_mgi_allele_id => 'set',
        get_mgi_allele_id => 'get',
    },
    default    => sub { {} }
);

has current_targ_rep_data_sth => (
    isa        => 'DBI::st',
    is         => 'ro',
    traits     => [ 'NoGetopt' ],
    init_arg   => undef,
    lazy_build => 1
);

sub _build_current_targ_rep_data_sth {
    my $self = shift;

    my $sth = $self->idcc_dbh->prepare( $CURRENT_TARG_REP_DATA_QUERY );
    $sth->execute;
    return $sth;
}

has current_htgt_data => (
    isa        => 'HashRef',
    traits     => [ 'NoGetopt', 'Hash' ],
    init_arg   => undef,
    handles    => {
        get_current_htgt_data => 'get',
    },
    lazy_build => 1
);

sub _build_current_htgt_data {
    my $self = shift;

    $self->htgt_schema->storage->dbh_do(
        sub {
            $_[1]->selectall_hashref( $CURRENT_HTGT_DATA_QUERY, 'CLONE_NAME' );
        }
    );
}

sub load_allele_names {
    my $self = shift;

    for ( qw( komp eucomm ) ) {
        $self->fetch_allele_data_for_pipeline( $_ );
    }

    if ( $self->want_update_targrep ) {
        $self->do_update_targrep;
    }

    if ( $self->want_update_htgt ) {
        $self->htgt_schema->txn_do(
            sub {
                $self->do_update_htgt;
                if ( ! $self->commit ) {
                    $self->log->warn( "Rollback" );
                    $self->htgt_schema->txn_rollback;
                }
            }
        );
    }

    return $self->err_exit ? 1 : 0;
}

sub do_update_targrep {
    my $self = shift;


    $self->log->debug( "Processing current targ_rep data" );

    my $sth = $self->current_targ_rep_data_sth;

    while ( my $r = $sth->fetchrow_arrayref ) {
        my ( $allele_id, $es_cell_id, $clone_name, $mgi_allele_id, $allele_superscript, $allele_symbol_superscript_template )
            = map { defined $_ ? $_ : '' } @{$r};

        my %to_update;

        my $new_mgi_allele_id = $self->get_mgi_allele_id( $clone_name );
        if ( $new_mgi_allele_id and $new_mgi_allele_id ne $mgi_allele_id ) {
            $to_update{mgi_allele_id} = $new_mgi_allele_id;
        }

        my $new_allele_superscript = $self->get_allele_superscript( $clone_name );
        if ( $new_allele_superscript and ($new_allele_superscript ne $allele_superscript or !$allele_symbol_superscript_template)) {
            $to_update{allele_symbol_superscript} = $new_allele_superscript;
        }

        #$self->log->info( "checking whether to update clone $clone_name, new:$new_allele_superscript, old: $allele_superscript" );

        if ( keys %to_update ) {
            $self->log->debug( "Updating targ_rep clone $clone_name: " . pp( \%to_update ) );
            try {
                if ( $self->commit ) {
                    $self->idcc_targ_rep->update_es_cell( $es_cell_id, \%to_update );
                }
            }
            catch {
                $self->log->error( $_ );
                $self->set_err_exit;
            };
        }
    }
}

sub do_update_htgt {
    my $self = shift;

    $self->log->debug( "Processing current HTGT data" );

    for my $clone_name ( $self->allele_clone_names ) {
        my $current = $self->get_current_htgt_data( $clone_name );
        unless ( $current ) {
            $self->log->warn( "Clone $clone_name not found in HTGT database" );
            next;
        }
        my $new_allele_name = $self->get_allele_name( $clone_name );

        if(length($new_allele_name) <= 0){
            $self->log->warn("$clone_name is having allele name reset in htgt - not doing this");
            return;
        }

        if ( ! $current->{ALLELE_NAME} ) {
            $self->create_htgt_well_data( $clone_name, $current->{WELL_ID}, 'allele_name', $new_allele_name );
        }
        elsif ( $current->{ALLELE_NAME} ne $new_allele_name ) {
            $self->update_htgt_well_data( $clone_name, $current->{WELL_ID}, 'allele_name', $new_allele_name );
        }
    }
}

sub update_htgt_well_data {
    my ( $self, $clone_name, $well_id, $data_type, $data_value ) = @_;

    my $wd = $self->htgt_schema->resultset( 'WellData' )->find(
        {
            'me.well_id'   => $well_id,
            'me.data_type' => $data_type
        }
    );

    unless ( $wd ) {
        $self->log->error( "Failed to retrieve $data_type well_data for $well_id" );
        $self->set_err_exit;
        return;
    }

    $self->log->info( "Updating $data_type well_data for $clone_name: " . $wd->data_value . " => $data_value" );
    $wd->update(
        {
            data_value => $data_value,
            edit_user  => $self->edit_user,
            edit_date  => \'current_timestamp'
        }
    );
}

sub create_htgt_well_data {
    my ( $self, $clone_name, $well_id, $data_type, $data_value ) = @_;

    my $well = $self->htgt_schema->resultset( 'Well' )->find(
        {
            well_id => $well_id
        }
    );

    unless ( $well ) {
        $self->log->error( "Failed to retrieve well $well_id" );
        $self->set_err_exit;
        return;
    }

    $self->log->info( "Creating $data_type well_data for $clone_name: $data_value" );
    $well->well_data_rs->create(
        {
            data_type  => $data_type,
            data_value => $data_value,
            edit_user  => $self->edit_user,
            edit_date  => \'current_timestamp'
        }
    );
}

sub fetch_allele_data_for_pipeline {
    my ( $self, $pipeline ) = @_;

    my $method = $pipeline . '_allele_report_url';
    my $url = $self->$method
        or return;

    $self->log->debug( "Downloading $url" );
    my $file = download_url_to_tmp_file( $url );

    $self->log->debug( "Parsing $url" );
    while ( my $line = $file->getline() ) {
        chomp $line;
        next if $line =~ /^#/ or not $line =~ /\S/;

        my ( $mgi_allele_id, $allele_symbol, $mutant_cell_line ) = ( split /\t/, $line )[ 2, 3, 7 ];

        unless ( defined $mgi_allele_id and defined $allele_symbol ) {
            $self->log->warn("failed to parse $line");
            next;
        }

        unless ( $mutant_cell_line ) {
            next;
        }

        my ( $allele_name, $allele_sup ) = $allele_symbol =~ /^(\S+)<(\S+)>$/;

        unless ( defined $allele_name and defined $allele_sup ) {
            $self->log->warn("failed to parse allele symbol: $allele_symbol");
            next;
        }

        my $new_allele_name = "$allele_name<sup>$allele_sup</sup>";

        my @cell_lines = split /,/, $mutant_cell_line;

        foreach my $epd_well_name (@cell_lines) {
            if ( $allele_symbol =~ /(Wtsi|Hmgu)/ ) {
                $self->set_allele_name( $epd_well_name, $new_allele_name );
            }
            $self->set_allele_superscript(  $epd_well_name, $allele_sup );
            $self->set_mgi_allele_id( $epd_well_name, $mgi_allele_id );
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__


