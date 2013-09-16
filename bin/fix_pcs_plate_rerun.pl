#!/usr/binenv perl

=head1 DESCRIPTION

Generate the commands to submit jobs with genomic region analysis for the PCS plates

=cut

use strict;
use warnings 'FATAL' => 'all';
use DateTime;

die "usage: $0 <plate> <project> ...\n" if @ARGV == 0 || @ARGV % 2;

my $exec   = '/software/team87/brave_new_world/bin/check_vector_mapping.pl';
my $cache  = '/software/team87/brave_new_world/data/qc/genomic_regions.store';
my $hash   = '/software/team87/brave_new_world/data/qc/genomic_regions';
my $outdir = '/nfs/users/nfs_t/team87/qc_runs';
my $format = <<"FORMAT";
bsub -q long -o %s -e %s -J '%s' '$exec -htgtlookup -dbstore -cache $cache -hash $hash -plate %s -tsproj %s'
FORMAT

while (@ARGV) {
  my $plate  = shift @ARGV;
  my $tsproj = shift @ARGV;
  my $now    = DateTime->now;
  my $prefix = "$plate.$tsproj." . sprintf( '%sT%s', $now->ymd, $now->hms );

  printf $format, "$outdir/$prefix.out", "$outdir/$prefix.err", $prefix, $plate, $tsproj;
}

exit 0;
