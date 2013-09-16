#!/usr/bin/env perl
# Ensure FP wells have same design instance as their parent EPD well
# $Id: fix_fp_well.pl 584 2009-12-11 11:09:13Z rm7 $
# see RT87948


use strict;
use warnings;

use Getopt::Long;
use HTGT::DBFactory;

my $updatedb;
my $debug;

GetOptions(
    "updatedb!"  => \$updatedb,
    "debug!"     => \$debug
) or die;

my $s = HTGT::DBFactory->connect( 'eucomm_vector' );

my $w_rs = $s->resultset(q(Well))->search({q(plate.type)=>q(FP)},{join=>q(plate)}); 
warn $w_rs->count." FP wells\n" if $debug; 
$w_rs=$w_rs->search({q(parent_well.well_id)=>{q(!=)=>undef}},{join=>q(parent_well)}); 
warn $w_rs->count." FP wells have parents\n" if $debug; 
warn $w_rs->search({q(me.design_instance_id)=>undef})->count." of which have null design instances\n" if $debug; 
$w_rs=$w_rs->search({q(dim_parent_well.well_id)=>undef},{join=>q(dim_parent_well)}); 
warn $w_rs->count." FP wells have parent with different (or null?) designs" if $debug; 
warn $w_rs->search({q(me.design_instance_id)=>undef})->count."  have null design instances" if $debug; 
my $w1=$w_rs->first; 
#warn "e.g. ".join", ",$w1->well_name,$w1->well_id,$w1->parent_well_id,$w1->design_instance_id if $debug; 
$s->txn_do(sub{ 
  my $naltered=0;
  while(my $w= $w_rs->next){
    if ($w->parent_well->design_instance_id or $w->design_instance_id){
      $naltered++;
      $w->inherit_from_parent([qw(cassette backbone)],{edit_user=>(getpwuid($<))[0]});
    }
  } 
  $w_rs= $s->resultset(q(Well))->search({q(plate.type)=>q(FP)},{join=>q(plate)})->search({q(dim_parent_well.well_id)=>undef, q(parent_well.well_id)=>{q(!=)=>undef}},{join=>[qw(dim_parent_well parent_well)]}); 
  warn $w_rs->count." FP wells now have parent with different designs\n" if $debug; 
  warn $w_rs->search({q(me.design_instance_id)=>undef})->count."  have null design instances\n" if $debug; 
  warn "$naltered FP wells updated\n" if ($debug or $naltered);
  die "No updated specified!\n" unless $updatedb; 
});


