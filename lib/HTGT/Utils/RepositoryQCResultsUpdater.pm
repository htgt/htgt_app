package HTGT::Utils::RepositoryQCResultsUpdater;

use strict;
use warnings FATAL => 'all';

use Carp;
use Text::CSV_XS;
use IO::File;
use Hash::Slice;
use Readonly;
use DateTime::Format::ISO8601;
use Log::Log4perl ':easy';

Readonly my @CSV_COLUMNS => qw(
    clone_name
    well_name
    fp_well_id
    first_test_start_date
    latest_test_completion_date
    karyotype
    copy_number_equals_one
    threep_loxp_srpcr
    fivep_loxp_srpcr
    vector_integrity
    loss_of_allele
    threep_loxp_taqman
    fivep_lrpcr
    wtsi_threep_lrpcr
    wtsi_threep_loxp_junction
    wtsi_distribute
);

Readonly my @DATE_COLUMNS => qw(
    first_test_start_date
    latest_test_completion_date
);

Readonly my @UPDATE_COLUMNS => qw(
    first_test_start_date
    latest_test_completion_date
    karyotype_low
    karyotype_high
    copy_number_equals_one
    threep_loxp_srpcr
    fivep_loxp_srpcr
    vector_integrity
    loss_of_allele
    threep_loxp_taqman
);

Readonly my %TRANSLATED_PLATE_NAMES => (
  'DEPD00118' => 'DEPD0003_8',
  'DEPD00121' => 'DEPD0003_11',
  'DEPD169' => 'DEPD00008_1',
  'DEPD170' => 'DEPD00008_2',
  'DEPD171' => 'DEPD00008_3',
  'DEPD172' => 'DEPD00008_4',
  'DEPD173' => 'DEPD00008_5',
  'DEPD174' => 'DEPD00008_6',
  'DEPD175' => 'DEPD00008_7',
  'DEPD176' => 'DEPD00008_8',
  'DEPD177' => 'DEPD00008_9',
  'DEPD178' => 'DEPD00008_10',

  'DEPD179' => 'DEPD00009_1',
  'DEPD180' => 'DEPD00009_2',
  'DEPD181' => 'DEPD00009_3',
  'DEPD182' => 'DEPD00009_4',
  'DEPD183' => 'DEPD00009_5',
  'DEPD184' => 'DEPD00009_6',
  'DEPD190' => 'DEPD00009_7',
  'DEPD194' => 'DEPD00009_8',
  'DEPD196' => 'DEPD00009_9',
  
  'DEPD185' => 'DEPD00010_1',
  'DEPD186' => 'DEPD00010_2',
  'DEPD187' => 'DEPD00010_3',
  'DEPD189' => 'DEPD00010_4',
  'DEPD191' => 'DEPD00010_5',
  'DEPD192' => 'DEPD00010_6',
  'DEPD193' => 'DEPD00010_7',
  
  
  'DEPD197' => 'DEPD00011_1',
  'DEPD198' => 'DEPD00011_2',
  'DEPD199' => 'DEPD00011_3',
  'DEPD200' => 'DEPD00011_4',
);

sub new {
    my ( $proto, $init_args ) = @_;
    my $class = ref( $proto ) || $proto;
    my $self = {};
    bless $self, $class;
    $self->init( $init_args );
}

sub init {
    my ( $self, $args ) = @_;
    $self->filename( $args->{ filename } )
        if $args->{ filename };
    $self->schema( $args->{ schema } )
        if $args->{ schema };

    my $csv = Text::CSV_XS->new( { allow_whitespace => 1 });
    $csv->column_names( @CSV_COLUMNS );
    $self->csv( $csv );      

    return $self;
}

sub filename {
    my $self = shift;
    if ( @_ ) {
        $self->{ filename } = shift @_;
    }
    my $filename = $self->{filename}
        or Carp::confess( 'input filename not specified' );
    return $filename;
}

sub schema {
    my $self = shift;
    if ( @_ ) {
        $self->{ schema } = shift @_;
    }
    my $schema = $self->{ schema }
        or Carp::confess( 'schema not specified' );
    return $schema;
}

sub csv {
    my $self = shift;
    if ( @_ ) {
        $self->{ csv } = shift @_;
    }
    my $csv = $self->{ csv }
        or Carp::confess( 'csv not specified' );
    return $csv;        
}

sub open_input_file {
    my $self     = shift;
    my $filename = $self->filename;
    DEBUG( "open_input_file: $filename" );
    my $ifh      = IO::File->new( $filename, O_RDONLY )
        or Carp::confess( "open $filename: $!" );

    $ifh->getline; # discard CSV header

    return $ifh;
}

sub find_well {
    my ( $self, $plate_name, $well_name ) = @_;

    DEBUG( "find_well: $plate_name\[$well_name\]" );
      
    my $well_rs = $self->schema->resultset( 'HTGTDB::Well' )->search(
        {
            'plate.name' => $plate_name,
            'well_name' => $well_name,
        },
        {
            join => 'plate'
        }
    );

    my $count = $well_rs->count;
    if ( $count == 0 ) {
        WARN( "Search for $well_name returned no wells" );
        return;
    }
    if ( $count > 1 ) {
        WARN( "Search for $well_name returned more than 1 well" );
        return;
    }

    return $well_rs->next;
}

sub get_next_record {
    my ( $self, $ifh ) = @_;
    
    my $data = $self->csv->getline_hr( $ifh )
        or Carp::confess( "CSV parse error" );

    unless ( !$data->{karyotype} || $data->{karyotype} =~ 'not done' || $data->{karyotype} =~ 'notdone' ) {
        my ( $klow, $khigh ) = $data->{karyotype} =~ qr/^(\d+)\s*-\s*(\d+)\%$/
            or Carp::confess( "failed to parse karyotype '$data->{karyotype}'" );
        $data->{karyotype_low} = $klow / 100;
        $data->{karyotype_high} = $khigh / 100;
    }

    ( $data->{plate_name} ) = $data->{well_name} =~ m/^(.+)_[^_]+$/
        or Carp::confess( "failed to parse well_name: $data->{well_name}" );

    if ( my $plate_name = $TRANSLATED_PLATE_NAMES{ $data->{plate_name} } ) {
        DEBUG( "Translating plate name $data->{plate_name} to $plate_name" );
        for ( $data->{well_name} ) {
            s/^$data->{plate_name}/$plate_name/;
            s/(?<=_[A-H])(\d)$/0$1/;
        }
        $data->{plate_name} = $plate_name;
    }
    
    for my $date_col ( @DATE_COLUMNS ) {
        $data->{ $date_col } = DateTime::Format::ISO8601->parse_datetime( $data->{ $date_col } )
            if $data->{ $date_col };
    }

    return $data;
}

sub update {
    my $self = shift;

    my $ifh = $self->open_input_file();
    
    $self->schema->txn_do(
        sub {
            while ( not $ifh->eof ) {
                my $data = $self->get_next_record( $ifh );
                DEBUG( "Read data for well: $data->{well_name}" );
                my $well = $self->find_well( $data->{plate_name}, $data->{well_name} )
                    or next;
                if ( my $qc_result = $well->repository_qc_result) {
                    $self->update_qc_result( $qc_result, $data );
                }
                else {
                    $self->insert_qc_result( $well, $data );
                }
            }
        }
    );
    return 1;
}

sub update_qc_result {
    my ( $self, $qc_result, $data ) = @_;

    DEBUG( "Updating data for $data->{well_name}" );
    for my $c ( @UPDATE_COLUMNS ) {
        $qc_result->$c( $data->{$c} );
    }
    $qc_result->update();
}

sub insert_qc_result {
    my ( $self, $well, $data ) = @_;

    DEBUG( "Inserting data for $data->{well_name}" );
    my $cols = Hash::Slice::slice( $data, @UPDATE_COLUMNS );
    $cols->{well_id} = $well->well_id;

    $self->schema->resultset( 'HTGTDB::RepositoryQCResult' )->create( $cols );
}

1;

__END__
