#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Carp 'carp', 'confess';
use Data::Dumper::Concise;
use English '-no_match_vars';
use Getopt::Long 'GetOptions';
use IO 'File';
use Pod::Usage 'pod2usage';
use Storable 'retrieve', 'store';

use Bio::SeqIO;
use Date::Format;
use Log::Log4perl ':easy';
use Readonly;
use Text::CSV_XS;

use ConstructQC;
use HTGTDB;
use HTGT::DBFactory;

use TargetedTrap::DBSQL::Database;
use TargetedTrap::IVSA::Design;
use TargetedTrap::IVSA::SyntheticConstruct;

BEGIN { Log::Log4perl->easy_init }

Readonly my $EMPTY_STRING => '';
Readonly my $UNDER_SCORE  => '_';
Readonly my $SINGLE_SPACE => ' ';
Readonly my $READ_LENGTH  => 2097152;

my %options;

GetOptions( \%options,
    qw/debug! output_file=s design_database=s qc_database=s/ );
vector_dump( \%options );

exit 0;

# retrieve the new designs
# - retrieve the plates of the genomic regions
# - retrieve the designs from plates not in genomic regions

sub _new_designs {
    my $htgtdb    = HTGT::DBFactory->connect('eucomm_vector');
    my $vector_qc = HTGT::DBFactory->connect('vector_qc');
    my $engseq_rs = $vector_qc->resultset('EngineeredSeq')
        ->search_rs( { 'me.is_genomic' => 1 }, { columns => ['name'] } );
    my %old_plates = map { split /_/, $_->name } $engseq_rs->all;
    my $plates_rs = $htgtdb->resultset('Plate')->search_rs(
        { 'me.type' => 'DESIGN' },
        { columns   => [ 'plate_id', 'name' ] },
    );
    return [
        map $_->plate_id,
        grep !exists $old_plates{ $_->name },
        $plates_rs->all
    ];
}

sub vector_dump {
    my $args = shift;

    unless ( $args->{output_file} ) {
        confess 'Please provide an output file';
    }

    my @desigb_db_params
        = HTGT::DBFactory->params( $args->{design_database} );
    my @qc_db_params = HTGT::DBFactory->params( $args->{qc_database} );

    my $design_db_htgtdb = HTGTDB->connect(@desigb_db_params)
        and printf "connected to %s\n",
        ( split /:/, $desigb_db_params[0] )[-1];

    my $design_db_tt = TargetedTrap::DBSQL::Database->new(
        {   '_user'     => $desigb_db_params[1],
            '_password' => $desigb_db_params[2],
            '_database' => ( split /:/, $desigb_db_params[0] )[-1],
        }
        )
        and printf "connected to %s\n",
        ( split /:/, $desigb_db_params[0] )[-1];

    my $construct_qc = ConstructQC->connect(@qc_db_params)
        and printf "connected to %s\n", ( split /:/, $qc_db_params[0] )[-1];

    my $vector_qc_db = TargetedTrap::DBSQL::Database->new(
        {   '_user'     => $qc_db_params[1],
            '_password' => $qc_db_params[2],
            '_database' => ( split /:/, $qc_db_params[0] )[-1],
        }
    ) and printf "connected to %s\n", ( split /:/, $qc_db_params[0] )[-1];

    my $mode      = -e $args->{output_file} ? '>>' : '>';
    my $bio_seqio = Bio::SeqIO->new(
        -file  => $mode . $args->{output_file},
        format => 'fasta'
    );

    ( my $hash_name = $args->{output_file} ) =~ s/\.\w+$//;

	my $store_file        = join( '.', $hash_name, 'store' );
    my %synthetic_vectors = -e $store_file ? %{ retrieve $store_file } : ();

    my $error_io = IO::File->new(
        join( $UNDER_SCORE,
            $hash_name, time2str( '%Y%m%d_%H%M', time ), 'errors.csv' ),
        'w'
    );

    my $csv_xs = Text::CSV_XS->new( { eol => "\n" } );

    $csv_xs->print( $error_io, [qw/plate well design design_instance/] );

    my $plates_rs = $design_db_htgtdb->resultset('HTGTDB::Plate')->search(
        { 'me.plate_id' => _new_designs() },
        { prefetch => [ { 'wells' => { 'design_instance' => 'design' } } ] }
    );

    INFO $plates_rs->count . ' plates to create';

PLATE: while ( my $plate = $plates_rs->next ) {
        my $wells_rs = $plate->wells;
        INFO "processing design plate [" . $plate->name . "]";

    WELL: while ( my $well = $wells_rs->next ) {
            my $plate_name  = $well->plate->name;
            my $well_name   = $well->well_name;
            my $unique_name = join $UNDER_SCORE, $plate_name, $well_name;

            next WELL if exists $synthetic_vectors{$unique_name};

            my $design_instance = $well->design_instance;

            unless ( defined $design_instance ) {
                $csv_xs->print( $error_io,
                    [ $plate_name, $well_name, 'NULL', 'NULL' ] );
                INFO "no design instance for $unique_name";
                next WELL;
            }

            my $bio_seq = eval {
                ( $design_instance->design
                        ->_wildtype_seq_without_seq_annotation )[0];
            };
            if ($EVAL_ERROR) {
                $csv_xs->print(
                    $error_io,
                    [   $plate_name,
                        $well_name,
                        $design_instance->design->design_id,
                        $design_instance->design_instance_id
                    ],
                );
                next WELL;
            }

            # Update the display id to PLATE_WELL
            $bio_seq->display_id($unique_name);

            # Write the sequence to FASTA file
            $bio_seqio->write_seq($bio_seq);

            # Write the sequence to database
            my $syn_vec
                = TargetedTrap::IVSA::SyntheticConstruct->new_from_bioseq(
                $bio_seq);

            $syn_vec->unique_tag($unique_name);
            $syn_vec->name($unique_name);
            $syn_vec->is_genomic(1);

            # Set up the design
            my $design = TargetedTrap::IVSA::Design->fetch_by_design_id(
                $design_db_tt, $design_instance->design->design_id );

            $design->plate( $plate->name );
            $design->well( $well->well_name );
            $design->primary_id( $design_instance->design_instance_id );

            $syn_vec->design($design);

            unless ( $args->{debug} ) {
                $syn_vec->store($vector_qc_db)
                    or confess 'Could not store Synthetic Construct';
            }

            # Cache the synthetic vector for storage
            $synthetic_vectors{$unique_name} = $syn_vec->primary_id;
            INFO 'inserted '
                . $unique_name
                . ' into database '
                . $syn_vec->primary_id
                if $syn_vec->primary_id;
        }

        last PLATE if $args->{debug};
    }

    $error_io->close
        or die 'Could not close error handle';

    if ( -s $args->{output_file} ) {
        system join( $SINGLE_SPACE,
            '/software/ssaha/ssaha2Build-1.0.9 -save',
            $hash_name, $args->{output_file} )
            and confess 'DNA Hashing failed';
    }

    # CheckVectorMapping needs to get this information for itself
    # removing this redundancy in the process
    store \%synthetic_vectors, $store_file
        and print 'Stored data in ', $store_file, "\n";
}

__END__

=pod

=head1 NAME

vector_dump.pl -- dump the genomic regions from all the wells

=head1 SYNOPSIS

  ./vector_dump.pl --output_file <output_file> --design_database <design_database> --qc_database <qc_database>

  Options:
    --debug

=head1 DESCRIPTION

  bsub -o ~/tmp/update_genomic_regions.%J.out -e ~/tmp/update_genomic_regions.%J.err -q basement -R 'select[mem>1500] rusage[mem=1500]' -M1500000 -J update_genomic_regions './vector_dump.pl -o ~/tmp/update_genomic_regions/genomic_regions.fa -design_database eucomm_vector -qc_database vector_qc'

=head1 FUNCTIONS

=head2 vector_dump

=cut

