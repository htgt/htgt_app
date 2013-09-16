#!/usr/bin/env perl

use strict;
use Getopt::Long;

use Data::Dumper;
use DateTime;
use HTGT::DBFactory;

my $dt       = DateTime->now;
my $run_date = $dt->day . '-' . $dt->month_name . '-' . $dt->year;
my $input_clone_name;

#$| = 1;

GetOptions(
    'clone_name:s'  => \$input_clone_name,
    'run_date'  => \$run_date,
    'debug|d'   => \my $debug,
    'verbose|v' => \my $verbose,
    'help|?'    => \my $help,
);

## Catch calls for help!

if ( $help || ( defined $ARGV[0] && $ARGV[0] =~ /\?|help/ ) ) {
  show_help();
  exit;
}

## Connect to the database...

my $schema  = HTGT::DBFactory->connect('kermits');
my $mig_dbh = HTGT::DBFactory->dbi_connect('mig');

my $clone_sql_piece = '';
if ($input_clone_name){
    $clone_sql_piece = " where clone = '$input_clone_name' ";
}

my $read_mig_data_sql = qq [
select
    scheduled_micro_injection_id, colony_prefix, clone, gene_name, mi_date, 
    number_transferred, number_et_recipients, number_et_recipients_np,
    number_born, number_chimeric, number_male, number_female,
    number_male_100_percent, number_male_lt_40_percent, number_male_gt_80_percent, number_male_40_to_80_percent,
    f0_breedings, f0_breedings_with_offspring, 
    f1_hets, f1_total,
    chimeras_with_hets, het_rate_100, het_rate_gt_50, het_rate_10_to_50, het_rate_lt_10, 
    ALL_MUTANT_descendents, 
    LIVE_MUTANT_descendents,
    test_cross_jax_short_name,
    backcross_jax_short_names,
    blast_jax_short_name,
    f1_black,
    (f1_agouti + f1_albino + f1_other_colour) as f1_non_black,
    neo_count_correct,
    vf4_vector_backbone_clear,
    vf6_vector_backbone_clear,
    mutant_pcr_assay_works,
    three_lr_pcr,
    homs_confirmed_by_srpcr,
    homs_by_qpcr,
    five_lr_pcr,
    loss_of_wt_allele_qpcr,
    loxp_pcr_works,
    lacz_srpcr_works,
    five_frt_srpcr_works,
    neo_short_range_pcr
    from mig.mir_to_kermits_mv
    $clone_sql_piece
];

my $sth = $mig_dbh->prepare($read_mig_data_sql);
$sth->execute();

my $bailout_count = 0;

# get the creator_id

my $creator = $schema->resultset('KermitsDB::PerPerson')->find(
  {
    first_name => 'Vivek',
    last_name  => 'Iyer'
  }
) or die "PerPerson lookup for Vivek Iyer failed";

my $creator_id = $creator->id;

$schema->txn_do(
  sub {
   ATTEMPT:
    while ( my $resultset_row = $sth->fetchrow_hashref() ) {
        process_row($resultset_row);
    }
    #die "ROLLBACK=====\n";
  }
);

sub process_row {
    my $row = shift;
    
      $bailout_count++;


      my $smi_id                  = $row->{SCHEDULED_MICRO_INJECTION_ID};
      my $colony_name             = $row->{COLONY_PREFIX};
      my $clone_name              = $row->{CLONE};
      my $gene_name               = $row->{GENE_NAME};
      my $latest_mi_date          = $row->{MI_DATE};
      my $number_transferred      = $row->{NUMBER_TRANSFERRED};
      my $number_et_recipients    = $row->{NUMBER_ET_RECIPIENTS};
      my $number_et_recipients_np = $row->{NUMBER_ET_RECIPIENTS_NP};
      my $number_born             = $row->{NUMBER_BORN};
      my $number_chimeric         = $row->{NUMBER_CHIMERIC};
      my $male_chim               = $row->{NUMBER_MALE};
      my $female_chim             = $row->{NUMBER_FEMALE};
      my $num_male_100            = $row->{NUMBER_MALE_100_PERCENT};
      my $num_male_less_40        = $row->{NUMBER_MALE_LT_40_PERCENT};
      my $num_male_gt_80          = $row->{NUMBER_MALE_GT_80_PERCENT};
      my $num_male_40_80          = $row->{NUMBER_MALE_40_TO_80_PERCENT};

      my $f0_breedings                = $row->{F0_BREEDINGS};
      my $f0_breedings_with_offspring = $row->{F0_BREEDINGS_WITH_OFFSPRING};
      my $f1_germ_line_mice           = $row->{F1_HETS};
      my $f1_total                    = $row->{F1_TOTAL};

      my $chimeras_with_glt            = $row->{CHIMERAS_WITH_HETS};
      my $number_100_percent_glt       = $row->{HET_RATE_100};
      my $number_gt_50_percent_glt     = $row->{HET_RATE_GT_50};
      my $number_btw_10_50_percent_glt = $row->{HET_RATE_10_TO_50};
      my $number_lt_10_percent_glt     = $row->{HET_RATE_LT_10};
      my $number_het_offspring         = $row->{ALL_MUTANT_DESCENDENTS};
      my $number_live_glt_offspring    = $row->{LIVE_MUTANT_DESCENDENTS};
      my $blast_jax_short_name         = $row->{BLAST_JAX_SHORT_NAME};
      my $test_cross_jax_short_name    = $row->{TEST_CROSS_JAX_SHORT_NAME};
      my $back_cross_jax_short_name    = $row->{BACKCROSS_JAX_SHORT_NAMES};
      my $f1_black                     = $row->{F1_BLACK};
      my $f1_non_black                 = $row->{F1_NON_BLACK};
    
      my $qc_five_prime_lr_pcr = convert_mig_pass($row->{FIVE_LR_PCR});
      my $qc_three_prime_lr_pcr = convert_mig_pass($row->{THREE_LR_PCR});
      
      my $qc_tv_backbone_assay = 'na';
      if(
        (convert_mig_pass($row->{VF4_VECTOR_BACKBONE_CLEAR}) eq 'pass') &&
        (convert_mig_pass($row->{VF6_VECTOR_BACKBONE_CLEAR}) eq 'pass')
      ){
        $qc_tv_backbone_assay = 'pass';
      }
      if(
        (convert_mig_pass($row->{VF4_VECTOR_BACKBONE_CLEAR}) eq 'fail') ||
        (convert_mig_pass($row->{VF6_VECTOR_BACKBONE_CLEAR}) eq 'fail')
      ){
        $qc_tv_backbone_assay = 'fail';
      }
        
      my $qc_loxp_confirmation = convert_mig_pass($row->{LOXP_PCR_WORKS});
      
      my $qc_loa_qpcr = convert_mig_pass($row->{LOSS_OF_WT_ALLELE_QPCR});
      
      my $qc_homozygous_loa_sr_pcr = convert_mig_pass($row->{HOMS_CONFIRMED_BY_SRPCR});
      
      my $qc_neo_count_qpcr = convert_mig_pass($row->{NEO_COUNT_CORRECT});
      
      my $qc_mutant_specific_sr_pcr = convert_mig_pass($row->{MUTANT_PCR_ASSAY_WORKS});
      
      my $qc_lacz_sr_pcr = convert_mig_pass($row->{LACZ_SRPCR_WORKS});
      
      my $qc_five_prime_cass_integrity = convert_mig_pass($row->{FIVE_FRT_SRPCR_WORKS});
      
      my $qc_neo_sr_pcr = convert_mig_pass($row->{NEO_SHORT_RANGE_PCR});

      #print "data: $colony_name, $clone_name, $latest_mi_date, $test_cross_jax_short_name, $back_cross_jax_short_name\n";

      next unless ($latest_mi_date);
      next unless ( $clone_name =~ /EPD/ );

      my $clone = $schema->resultset('KermitsDB::EmiClone')->find( { clone_name => $clone_name } );

      if ( !$clone ) {
        warn "cant find clone $clone - this is supposed to be an update!";
        next ATTEMPT;
      }
      else {
        print "found clone with name: $clone_name\n";    # print "clone id: $clone->id\n";
      }

      my $converted_date = get_oracle_date($latest_mi_date);

      my @events = $clone->events();
      my $event;
      foreach my $poss_event (@events) {
        if ( $poss_event->centre_id == 1 ) {
          $event = $poss_event;
          last;
        }
      }

      if ($event) {
        print "found event\n";
      } else {
        warn "cant find events for clone $clone_name - this is supposed to be an update!";
        next ATTEMPT;
      }

      my @attempts = $event->attempts;
      my $attempt;
      foreach my $found_attempt (@attempts) {
        my $found_production_centre_mi_id = $found_attempt->production_centre_mi_id;
        if ( $found_production_centre_mi_id == $smi_id ) {
          $attempt = $found_attempt;
        }
      }

      if ( !$attempt ) {
        warn "cant find attempt for clone $clone_name, event ".$event->id.'- this is supposed to be an update';
        next ATTEMPT;
      } else {

        $attempt->update(
          {

            qc_five_prime_lr_pcr => $qc_five_prime_lr_pcr,
            qc_three_prime_lr_pcr => $qc_three_prime_lr_pcr,
            qc_tv_backbone_assay => $qc_tv_backbone_assay,
            qc_loxp_confirmation => $qc_loxp_confirmation,
            qc_loa_qpcr => $qc_loa_qpcr,
            qc_homozygous_loa_sr_pcr => $qc_homozygous_loa_sr_pcr,
            qc_mutant_specific_sr_pcr => $qc_mutant_specific_sr_pcr,
            qc_neo_count_qpcr => $qc_neo_count_qpcr,
            qc_lacz_sr_pcr => $qc_lacz_sr_pcr,
            qc_five_prime_cass_integrity => $qc_five_prime_cass_integrity,
            qc_neo_sr_pcr => $qc_neo_sr_pcr,
        
            edited_by => 'vvi',
            edit_date => $run_date

          }
        );

        print "updated attempt: "
         . $attempt->id . ","
         . $attempt->is_active
         . ", $converted_date, $colony_name, $clone_name, $number_het_offspring, smi: $smi_id\n";
    
      }
}#End While

sub get_oracle_date {
  my $date_str = shift;
  my $day;
  my $mon;
  my $year;
  if ( $date_str =~ /(\d+)\/(\d+)\/(\d+)/ ) {
    $day  = $1;
    $mon  = $2;
    $year = $3;
  }
  elsif ( $date_str =~ /^\d-\w*-\d\d/ ) {
    return qq[0${date_str}];
  }
  elsif ( $date_str =~ /^\d\d-\w*-\d\d/ ) {
    return $date_str;
  }
  else {
    die "cant match date $date_str\n";
  }
  my $months = {
    '01' => 'JAN',
    '02' => 'FEB',
    '03' => 'MAR',
    '04' => 'APR',
    '05' => 'MAY',
    '06' => 'JUN',
    '07' => 'JUL',
    '08' => 'AUG',
    '09' => 'SEP',
    '10' => 'OCT',
    '11' => 'NOV',
    '12' => 'DEC'
  };
  my $chosen_month = $months->{$mon};
  if ( !$chosen_month ) {
    die "cant get month str for $mon\n";
  }
  my $return_string = "${day}-${chosen_month}-$year";
  return $return_string;
}

# Perl trim function to remove whitespace from the start and end of the string
sub trim($) {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

sub convert_mig_pass {
  my $pass = shift;
  if($pass){
    if($pass eq 'Yes'){
      return 'pass';
    }
    if($pass eq 'No'){
      return 'fail';
    }
    if($pass eq 'Failed'){
      return 'fail';
    }
    if($pass eq 'Problem Line'){
      return 'fail';
    }
    if($pass eq 'N/A'){
      return 'na';
    }
    if($pass eq 'Not Done'){
      return 'na';
    }
    if($pass eq 'Not Yet'){
      return 'na';
    }
    
    die "unrecognised mig pass level: $pass\n";
  }else{
    return 'na';
  }
}
