#!/usr/bin/env perl
#  Dump out synthetic vectors
# $Id: dump_synthetic_targeting_vectors.pl 632 2009-12-16 11:40:03Z rm7 $

use strict;
use warnings;

use Bio::SeqIO;
use Getopt::Long;
use HTGT::DBFactory;

GetOptions(
    "debug!"     => \my $debug
) or die;

my $s = HTGT::DBFactory->connect( 'eucomm_vector' );
my $so=Bio::SeqIO->new(-fh=>\*STDOUT, -format=>q(genbank));

my $p_rs = $s->resultset(q(Project)); 
warn $p_rs->count." projects\n" if $debug; 
$p_rs= $p_rs->search({cassette=>{q(!=) => undef}, backbone=>{q(!=) => undef}},{order_by=>q(design_id)});
warn $p_rs->count. " have cassette and backbone\n" if $debug; 
while (my $p=$p_rs->next){
  warn join(", ",$p->design_id, $p->cassette, $p->backbone, $p->design->is_deletion?"del":"")."\n" if $debug; 
  eval{ my $seq=$p->design->vector_seq($p->cassette, $p->backbone)  ; $so->write_seq($seq);}; 
  warn $@ if $@; 
}
