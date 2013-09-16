#!/usr/bin/env perl

use strict;
use Getopt::Long;
use Data::Dumper;
use HTGT::DBFactory;
use DBI;
use Pod::Usage;

my @imits_cosortia = ('MGP', 'UCD-KOMP', 'EUCOMM-EUMODIC');

GetOptions(
    'help'    => sub { pod2usage( -verbose => 1 ) },
    "debug"     => \my $debug,
    "imits_csv"     => \my $imits_csv,
    "htgt_csv"     => \my $htgt_csv,
    "commit"     => \my $live,
    "delete"     => \my $delete,
) or pod2usage(2);

my $imits_connection = 'imits';
my $htgt_connection = 'eucomm_vector_esmp';

print "Using $imits_connection/$htgt_connection\n";

go_live();

#Task #8760

#Find all ES Cells (KOMP-CSD and EUCOMM) attached to known iMITS MI's.
#
#Find those which have been marked non-distributable in HTGT. There WILL be a set, because Ed Ryder is complaining about them. Restore these clones as distributable, but make sure that they have 5/3/lox all FAIL in htgt (and so in targrep).
#
#The point here is that we cannot kick material out of targrep if people have made a mouse on it, we can just mark it as failing qc. Here are the clones that Ed is finding problematic:
#
#We have a number of mouse colonies where the ES clone ID has been withdrawn from release at a later date. The result of this is that we cannot do a biomart search on a cross table lookup of the mouse and ES cell QC to determine what work was done on it prior to MI. This is data that Ramiro requires for reporting purposes. List is shown below.
#Vivek: is there a way to automatically check for derived mouse lines before clones are withdrawn after MI has occurred so you don’t all get bogged down by me sending lists out in the future?
#
#On a related note Wendy mentioned that you have a ‘b’ pass category for the cells. However on a biomart search of targeted products I can’t seem to see this entry. Could you send me a couple of examples of clone IDs so I can check I’m not doing something obviously wrong please?
#
#Cheers
#Ed
#
#Lines not in IKMC: targeted products

# colony_name | es_cell_name  |     gene      | consortium
#-------------+---------------+---------------+------------
# MEYW        | EPD0109_7_E02 | Maoa          | MGP
# MEVW        | EPD0415_3_C03 | Ankrd9        | MGP
# MENG        | EPD0614_5_B03 | A830019P07Rik | MGP
# METR        | EPD0582_1_B10 | Myo5b         | MGP
# MEXM        | EPD0554_6_B01 | Cyp2s1        | BaSH
# MEWG        | EPD0763_1_A08 | Arhgap24      | MGP
# MEYP        | EPD0337_2_C10 | Cenpl         | MGP
# MEUM        | EPD0626_2_H09 | Tgm6          | MGP
# MEUD        | EPD0486_1_A03 | Med6          | MGP
# MEXF        | EPD0536_2_D07 | 4933411K20Rik | MGP
# MEUH        | EPD0516_2_A11 | Inmt          | MGP
# MEVG        | EPD0587_2_E12 | Fzd6          | MGP
# MEXV        | EPD0419_4_B09 | Nek9          | MGP
# MEXL        | EPD0554_6_B01 | Cyp2s1        | BaSH

################################################################################

print "Using iMits consortia: " . join(', ', @imits_cosortia) . "\n";
print "Debug!\n" if($debug);
print "Not live!\n" if(!$live);
print "Using iMits: $imits_connection - HTGT: $htgt_connection\n";

#print "Not configured to go live!\n" if($live);
#exit if($live);

my @names = get_imits_es_cells();
exit if($imits_csv);

my $start = 0;
my $step = 500;
my $counter = 0;
my $add_header = 1;
my @epd_well_id_array;

# loop through in chunks since it barfs if we try to use too many es cell names in one go

my @htgt_csv;
while(my @subkeys = splice(@names, $start, $step)) {
  my $names = join ', ', map { qq/'$_'/ } @subkeys;
  push @epd_well_id_array, get_htgt_well_ids($names);
  $counter += scalar @subkeys;
}

if($htgt_csv) {
  my $csv = join("\n", @htgt_csv);
  open (CSVFILE, '>htgt.csv');
  print CSVFILE "$csv";
  close (CSVFILE);
}

exit if($htgt_csv);

my %hash   = map { $_ => 1 } @epd_well_id_array;
@epd_well_id_array = keys %hash;

#if($delete) {
#  delete_htgt_distributable(\@epd_well_id_array);
#  exit;
#}

update_htgt_distributable(\@epd_well_id_array);

################################################################################

# routine to see the list as described by Ed

#sub list_imits_details
#{
#  my $dbh = HTGT::DBFactory->dbi_connect( 'imits_test', { AutoCommit => 1 } );
#
#  my $sth = $dbh->prepare(qq [
#    select a.colony_name as colony_name,e.name as es_cell_name,g.marker_symbol as gene,c.name as consortium
#    from es_cells e, mi_attempts a, consortia c, mi_plans p, genes g
#    where e.id = a.es_cell_id and p.id = a.mi_plan_id
#    and p.consortium_id = c.id
#    and g.id = e.gene_id and g.marker_symbol in (
#    'A830019P07Rik', 'Myo5b', 'Med6', 'Inmt', 'Tgm6', 'Fzd6', 'Ankrd9', 'Arhgap24', '4933411K20Rik', 'Cyp2s1', 'Nek9', 'Cenpl', 'Maoa'
#    )
#    and e.name in
#    (
#    'EPD0614_5_B03', 'EPD0582_1_B10', 'EPD0486_1_A03', 'EPD0516_2_A11', 'EPD0626_2_H09', 'EPD0587_2_E12', 'EPD0415_3_C03',
#    'EPD0763_1_A08', 'EPD0536_2_D07', 'EPD0554_6_B01', 'EPD0419_4_B09', 'EPD0337_2_C10', 'EPD0109_7_E02'
#    );
#  ]);
#
#  $sth->execute();
#
#  my $add_header = 1;
#  while ( my $ref = $sth->fetchrow_hashref() ) {
#    if($add_header) {
#      my @keys = keys %{$ref};
#      my $header = join ',', map { qq/$_/ } @keys;
#      print "$header\n";
#      $add_header = 0;
#    }
#
#    my @values = values %{$ref};
#    my $row = join ',', map { qq/$_/ } @values;
#    print "$row\n";
#  }
#}

################################################################################

sub get_imits_es_cells
{
  my $cosortia = join ', ', map { qq/'$_'/ } @imits_cosortia;
  my $dbh = HTGT::DBFactory->dbi_connect( $imits_connection, { AutoCommit => 1 } );

  my $sth = $dbh->prepare(qq [
    select e.name from es_cells e, mi_attempts a, consortia c, mi_plans p
    where e.id = a.es_cell_id and p.id = a.mi_plan_id and p.consortium_id = c.id and c.name in ($cosortia);
  ]);

  $sth->execute();

  my @csv;
  push(@csv, "es_cell_name") if($imits_csv);

  my @array;
  while(my @results= $sth->fetchrow_array()){
    push @array, $results[0];
    push(@csv, $results[0]) if($imits_csv);
  }

  if($imits_csv) {
    my $csv = join("\n", @csv);
    open (CSVFILE, '>imits.csv');
    print CSVFILE "$csv";
    close (CSVFILE);
  }

  return @array;
}

################################################################################

#EPD_DISTRIBUTE = [ undef, 'yes' ];
#EPD_THREE_ARM_PASS_LEVEL = [ undef, 'nd', 'pass', 'fail' ];
#EPD_FIVE_ARM_PASS_LEVEL = [ undef, 'nd', 'pass', 'na', 'fail' ];
#EPD_LOXP_PASS_LEVEL = [ undef, 'nd', 'pass', 'fail' ];

sub get_htgt_well_ids
{
  my $names = shift;

  my $dbh = HTGT::DBFactory->dbi_connect( $htgt_connection, { AutoCommit => 1 } );

  my $sth = $dbh->prepare(qq [
    select *
    from new_well_summary
    where epd_well_name in ($names)
    and EPD_DISTRIBUTE is null
  ]);

  #and (EPD_THREE_ARM_PASS_LEVEL is null or EPD_THREE_ARM_PASS_LEVEL != 'pass')
  #and (EPD_FIVE_ARM_PASS_LEVEL is null or EPD_FIVE_ARM_PASS_LEVEL != 'pass')
  #and (EPD_LOXP_PASS_LEVEL is null or EPD_LOXP_PASS_LEVEL != 'pass')

  $sth->execute();

  my @array;

  while ( my $ref = $sth->fetchrow_hashref() ) {
    if($add_header) {
      my @keys = keys %{$ref};
      my $header = join ',', map { qq/$_/ } @keys;
      push(@htgt_csv, $header) if($htgt_csv);
      $add_header = 0;
    }

    my @values = values %{$ref};
    my $row = join ',', map { qq/$_/ } @values;
    push(@htgt_csv, $row) if($htgt_csv);

    push @array, $ref->{'EPD_WELL_ID'};
  }

  return @array;
}

################################################################################

sub update_htgt_distributable
{
  my $array = shift;
  my @array = @{$array};

  print "Attempting to insert " . scalar(@array) . " rows!\n";

  my $ids = join ', ', map { qq/$_/ } @array;

  my $dbh = HTGT::DBFactory->dbi_connect( $htgt_connection, { AutoCommit => 0 } );

  # paranoid check
  # indicates we've run this before and probably should not be running it again

  my $sth = $dbh->prepare(qq [
    select *
    from well_data
    where well_id in ($ids)
    and data_type = 'distribute'
  ]);

  $sth->execute();

  my $counter = 0;
  while ( my $ref = $sth->fetchrow_hashref() ) {
    $counter += 1;
    last;
  }

  die "Not expecting to find any rows!\n" if $counter;

  my $sth = $dbh->prepare_cached(qq [
    insert into well_data (DATA_VALUE, WELL_ID, DATA_TYPE, EDIT_USER) values ('yes', ?, 'distribute', 're4')
  ]);

  die "Couldn't prepare queries; aborting: $DBI::errstr\n" unless defined $sth;

  foreach my $id (@array) {
    print "ID: $id\n" if($debug);
    $sth->execute($id) or warn "Cannot insert $id: $DBI::errstr\n";
  }

  if(!$live) {
    print "Rolling back...\n";
    $dbh->rollback();
  }

  if($live) {
    print "Committing...\n";
    $dbh->commit();
  }

  if($delete) {
    my $sql = qq [
      delete
      from well_data
      where well_id in ($ids)
      and data_type = 'distribute'
      and EDIT_USER = 're4'
    ];
    print "SQL: $sql";
  }

  $dbh->disconnect or warn "Disconnection failed: $DBI::errstr\n";
}

################################################################################

#sub delete_htgt_distributable
#{
#  my $array = shift;
#  my @array = @{$array};
#
#  print "Attempting to delete " . scalar(@array) . " rows!\n";
#
#  my $ids = join ', ', map { qq/$_/ } @array;
#
#  my $dbh = HTGT::DBFactory->dbi_connect( $htgt_connection, { AutoCommit => 0 } );
#
#  my $sth = $dbh->prepare(qq [
#    delete
#    from well_data
#    where well_id in ($ids)
#    and data_type = 'distribute'
#    and EDIT_USER = 're4'
#  ]);
#
#  $sth->execute();
#
#  if(!$live) {
#    print "Rolling back...\n";
#    $dbh->rollback();
#  }
#
#  #if($live) {
#  #  print "Committing...\n";
#  #  $dbh->commit();
#  #}
#
#  $dbh->disconnect or warn "Disconnection failed: $DBI::errstr\n";
#}

################################################################################

sub go_live
{
  if($live) {
    print "Committing to live db? yes/no (y/n) ";
    chomp ( my $res = <STDIN>);
    if ($res ne "y") {
      print "quit!\n";
      exit;
    }
    #print "go!\n";
  }
}

################################################################################

__END__

=pod

=head1 NAME

restore_missing_es_cells_to_htgt.pl

=head1 SYNOPSIS

  restore_missing_es_cells_to_htgt.pl [OPTIONS]

  Options:

    --help        Display a brief help message
    --debug       Debug mode
    --imits_csv   Output csv from imits
    --htgt_csv    Output csv from htgt
    --commit      Live mode
    --delete      Show sql string to delete rows previously added

=head1 DESCRIPTION

This program searches the iMits database for es cells from particular consortia.
It then goes to htgt using those es cell names to find cells that have failed 3/5/lox.
It sets those cells to distributable in htgt.

=head1 AUTHOR

Richard Easty

=cut
