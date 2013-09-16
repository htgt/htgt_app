#!/usr/bin/env perl
# $Id: check_plate_relationships.pl 586 2009-12-11 11:14:16Z rm7 $
# Will check the parent and child plates by using the well parents and children

use strict;
use warnings;

use Getopt::Long;
use HTGT::DBFactory;

my $updatedb;
my $platename;
my $delete=1;
my $debug;

GetOptions(
        "updatedb"    => \$updatedb,
        "platename=s" => \$platename,
        "delete!"     => \$delete,
        "debug"       => \$debug
) or die;

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

$htgt->txn_do(sub {

  #find the plates
  my $platers = $htgt->resultset(q(Plate));
  my $tprs = $platename ? $platers->search_like({name=>$platename}) : $platers ;
  while(my $tp = $tprs->next){
    warn "Plate ".$tp->name." (".$tp->id.")\n" if $debug;
    my $pprs = $tp->parent_plates_from_parent_wells;
    warn " parent plates (from wells) : ".join(", ",map{$_->name." (".$_->id.")"}$pprs->all)."\n" if $debug;
    warn " parent plates (previous)   : ".join(", ",map{$_->name." (".$_->id.")"}$tp->parent_plates->all)."\n" if $debug;
    my $ppprs = $tp->parent_plate_plates;
    while (my $pp = $pprs->next){$ppprs->find_or_create({parent_plate=>$pp})}
    if($delete){while (my $ppp = $ppprs->next){$ppp->delete unless $pprs->find($ppp->parent_plate->id)}}
    warn " parent plates (now)        : ".join(", ",map{$_->name." (".$_->id.")"}$tp->parent_plates->all)."\n" if $debug;

    my $cprs = $tp->child_plates_from_child_wells;
    warn " child  plates (from wells) : ".join(", ",map{$_->name." (".$_->id.")"}$cprs->all)."\n" if $debug;
    warn " child  plates (previous)   : ".join(", ",map{$_->name." (".$_->id.")"}$tp->child_plates->all)."\n" if $debug;
    my $cpprs = $tp->child_plate_plates;
    while (my $cp = $cprs->next){$cpprs->find_or_create({child_plate=>$cp})}
    if($delete){while (my $cpp = $cpprs->next){$cpp->delete unless $cprs->find($cpp->child_plate->id)}}
    warn " child  plates (now)        : ".join(", ",map{$_->name." (".$_->id.")"}$tp->child_plates->all)."\n" if $debug;

  }

  die "DB update not specified!\n" unless $updatedb;
});

