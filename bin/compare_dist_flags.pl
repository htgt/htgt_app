#!/usr/bin/env perl

# $Id: compare_dist_flags.pl 4902 2011-05-09 15:00:24Z do2 $
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/compare_dist_flags.pl $
# $LastChangedRevision: 4902 $
# $LastChangedDate: 2011-05-09 16:00:24 +0100 (Mon, 09 May 2011) $
# $LastChangedBy: do2 $

use strict;

use Log::Log4perl qw( :levels );
use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory;

##
## Get the user-defined options for the program...
##

my $verbose;
GetOptions(
  'verbose|v!'      => \$verbose,
  'help'          => sub { pod2usage( -verbose => 1 ) },
  'man'           => sub { pod2usage( -verbose => 2 ) },
);

##
## Set-up...
##

if ( $verbose ) { Log::Log4perl->easy_init( $DEBUG ); }
else            { Log::Log4perl->easy_init( $INFO );  }

my $logger      = Log::Log4perl->get_logger();
my $htgt_schema = HTGT::DBFactory->connect('eucomm_vector') or die "ERROR: HTGT Database connection not made! \n";;

open(LOG,">off_from_tony.csv");
my @headers = qw/
  epd_clone
  tony_dist_flag
  lf
  lr
  lrr
  r1r
  r2r
  clone_plate
  di
  gr_count
  gf_count
  tr_pcr
  5'arm
  loxP
  3'arm
  auto_dist_flag
/;
print LOG ( join(",", @headers) . "\n" );

##
## Get on with it...
##

my $plate_rs = $htgt_schema->resultset('Plate')->search(
  {
    # name => { 'like', 'EPD0025_5' },
    type => ['EPD','REPD']
  },
  { order_by => 'name asc' }
);

my $tot_plate = $plate_rs->count;
my $cur_plate = 1;
my $well_count = 0;
my $well_count_good = 0;
my $well_count_bad = 0;

while ( my $plate = $plate_rs->next ) {
  
  $logger->debug("[ ".$cur_plate." / ".$tot_plate." ] ".$plate->name);
  $cur_plate++;
  
  foreach my $well ( $plate->wells ) {
    
    my $tony_distribute_flag;
    $well_count++;
    
    my $distr_well_data = $htgt_schema->resultset('WellData')->find(
      { well_id => $well->well_id,  data_type => 'distribute' },
      { key => 'well_id_data_type' }
    );
    
    my $trap_well_data = $htgt_schema->resultset('WellData')->find(
      { well_id => $well->well_id,  data_type => 'targeted_trap' },
      { key => 'well_id_data_type' }
    );
    
    if ( $distr_well_data and $distr_well_data->data_value eq 'yes' ) {
      $tony_distribute_flag = 'distribute';
    }
    elsif ( $trap_well_data and $trap_well_data->data_value eq 'yes' ) {
      $tony_distribute_flag = 'targeted_trap';
    }
    else {
      $tony_distribute_flag = 'no';
    }
    
    if ( $tony_distribute_flag eq $well->distribute ) {
      # Yay! We agree with Tony!
      $well_count_good++;
    }
    else {
      # Boo! We don't agree with Tony...
      $well_count_bad++;
      
      my $reads_and_bands = $well->get_primer_reads_and_bands;
      
      my $lf  = 0;
      my $lr  = 0;
      my $lrr = 0;
      my $r1r = 0;
      my $r2r = 0;
      my @clone_plate     = ();
      my @design_instance = ();
      
      foreach my $read ( @{$reads_and_bands->{reads}} ) {
        $lf  += $read->{lf}  if $read->{lf};
        $lr  += $read->{lr}  if $read->{lr};
        $lrr += $read->{lrr} if $read->{lrr};
        $r1r += $read->{r1r} if $read->{r1r};
        $r2r += $read->{r2r} if $read->{r2r};
        push( @clone_plate, $read->{clone_plate} ) if $read->{clone_plate};
        push( @design_instance, $read->{primer_design_instance_id} ) if $read->{primer_design_instance_id};
      }
      
      my $data_to_dump = [
        $well->well_name,
        $tony_distribute_flag,
        $lf,
        $lr,
        $lrr,
        $r1r,
        $r2r,
        join( '; ', @clone_plate ),
        join( '; ', @design_instance ),
        $reads_and_bands->{bands}->{gr},
        $reads_and_bands->{bands}->{gf},
        $reads_and_bands->{bands}->{tr},
        $well->five_arm_pass_level,
        $well->loxP_pass_level,
        $well->three_arm_pass_level,
        $well->distribute
      ];
      
      print LOG ( join(",", @{$data_to_dump}) . "\n" );
    }
  }
}


$logger->debug("Finished");
$logger->debug("Processed ".$well_count." wells");
$logger->debug($well_count_good." were correct");
$logger->debug($well_count_bad." were wrong");

close(LOG);

###
### Subroutine(s)
###

sub three84_well_qc {
  my ( $options ) = @_;
  my $plate_rs = $options->{htgt_schema}->resultset('Plate')->search(
    {
      'plate_data.data_type'  => 'is_384',
      'plate_data.data_value' => 'yes'
    },
    { join => 'plate_data' }
  );

  while ( my $plate = $plate_rs->next ) {
    if ( $plate->name =~ /^PC/ ) { $options->{stage} = 'post_cre'; }
    else                         { $options->{stage} = 'post_gateway'; }
    $plate->load_384well_qc( $options );
  }
}

sub qc_by_type {
  my ( $options, $stage, $plate_type ) = @_;
  $options->{stage} = $stage;
  my $plate_rs = 
    $options->{htgt_schema}->resultset('Plate')->search({ type => $plate_type });
  while ( my $plate = $plate_rs->next ) { $plate->load_qc( $options ); }
}

__END__

=pod

=head1 NAME

compare_dist_flags.pl

=head1 SYNOPSIS

perl compare_dist_flags.pl [options]

=head1 OPTIONS

=over 8

=item B<--verbose>

Print output as the script runs (otherwise the script is silent).

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print the manual page and exit.

=back

=head1 DESCRIPTION

B<compare_dist_flags.pl> - Script to produce a report for Tony comparing the automated LoxP,3',5' QC calls against his distribute flags.  Produces a CSV file containing any calls that mismatch.

=head1 AUTHOR

Darren Oakley E<lt>do2@sanger.ac.ukE<gt>.

=cut

