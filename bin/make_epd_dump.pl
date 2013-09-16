#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use IO 'File';
use Text::CSV_XS;
use HTGT::DBFactory;

GetOptions(
    'debug!'      => \my $debug,
    'verbose!'    => \my $verbose,
    'help|?'      => \my $help,
    'outfile=s'   => \my $outfile,
);

my @columns = qw/
  PROJECT_ID EUCOMM KOMP MGP NORCOMM MGI DESIGN DESIGN_ID
  DESIGN_INSTANCE_ID DESIGN_TYPE PCS_PLATE PCS_WELL PC_CLONE
  PCS_QC_RESULT PCS_QC_RESULT_ID PCS_DISTRIBUTE PCS_COMMENTS
  PGS_PLATE PGS_WELL PGS_WELL_ID CASSETTE BACKBONE PG_CLONE
  PGS_QC_RESULT PGS_QC_RESULT_ID PGS_DISTRIBUTE PGS_COMMENTS
  EPD ES_CELL_LINE CELL_LINE_PASSAGE EPD_DISTRIBUTE TARGETED_TRAP
  EPD_COMMENTS FP_WELL_NAME MARKER_SYMBOL ENSEMBL_GENE_ID
  VEGA_GENE_ID FIVE_ARM_PASS_LEVEL LOXP_PASS_LEVEL
  THREE_ARM_PASS_LEVEL
  /;
my $handle = $outfile ? IO::File->new( $outfile, 'w' ) : \*STDOUT;
my $indel  = qr/(Del|Ins)/;
my $spaces = qr/\cM\s*\n/;
my $parser = Text::CSV_XS->new( { eol => "\n", always_quote => 1 } );
my $schema = HTGT::DBFactory->connect( 'eucomm_vector' );

my $results =
  $schema->resultset('HTGTDB::Result::EPDDump')
  ->search( {}, { prefetch => ['well'] } );

$parser->print( $handle, [@columns] );

my $count = 0;
ROW: while ( my $row = $results->next ) {
    unless ( $row->well ) {
        warn 'no well found for ', $row->epd;
        next ROW;
    }

    # Set to 'Cnd' unless we have an 'Ins'ertion or 'Del'etion
    $row->design_type( defined $row->design_type
          && $row->design_type =~ m/$indel/ ? $1 : 'Cnd' );

    # Print the row to our output handle
    $parser->print(
        $handle,
        [
            map { local $_ = defined($_) ? $_ : ''; s/$spaces//; $_ }
            $row->project_id,
            $row->eucomm,                    $row->komp,
            $row->mgp,                       $row->norcomm,
            $row->mgi,                       $row->design,
            $row->design_id,                 $row->design_instance_id,
            $row->design_type,               $row->pcs_plate,
            $row->pcs_well,                  $row->pc_clone,
            $row->pcs_qc_result,             $row->pcs_qc_result_id,
            $row->pcs_distribute,            $row->pcs_comments,
            $row->pgs_plate,                 $row->pgs_well,
            $row->pgs_well_id,               $row->cassette,
            $row->backbone,                  $row->pg_clone,
            $row->pgs_qc_result,             $row->pgs_qc_result_id,
            $row->pgs_distribute,            $row->pgs_comments,
            $row->epd,                       $row->es_cell_line,
            $row->cell_line_passage,         $row->epd_distribute,
            $row->targeted_trap,             $row->epd_comments,
            $row->fp,                        $row->marker_symbol,
            $row->ensembl_gene_id,           $row->vega_gene_id,
            $row->well->five_arm_pass_level, $row->well->loxP_pass_level,
            $row->well->three_arm_pass_level,
        ],
    );

    last ROW if ++$count >= 1 && $debug;
}

if ($outfile) {
    $handle->close
      or die "Could not close out handle ($outfile)";
}

exit 0;

__END__

=pod

=head1 NAME

make_epd_dump.pl --

=head1 SYNOPSIS

cd ${YOUR_HTGT_SRC_CHECKOUT_DIRECTORY}
perl -I lib/ script/cron/make_epd_dump.pl [options]

  Options:
    -production
    -outfile
    -debug
    -verbose
    -help|?

=head1 OPTIONS

=over 8

=item B<production>

Flag to activate the use of LIVE/PRODUCTION database

=item B<outfile>

File to write the results to (defaults to STDOUT)

=item B<debug>

=item B<help>

=item B<verbose>

=back

=head1 DESCRIPTION


=cut
