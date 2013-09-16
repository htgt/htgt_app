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

my $schema    = HTGT::DBFactory->connect('kermits');
my $eu_schema = HTGT::DBFactory->connect('eucomm_vector');
my $mig_dbh   = HTGT::DBFactory->dbi_connect('mig');

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
    (f1_agouti + f1_albino + f1_other_colour) as f1_non_black
    from mig.mir_to_kermits_mv
    $clone_sql_piece
];

#print "$read_mig_data_sql\n";

#select colony_prefix, clone, gene_name, latest_mi_date, number_transferred, number_et_recipients, number_et_recipients_np,
#         number_born, number_chimeric, number_male, number_female,
#         number_100_percent, number_lt_40_percent, number_gt_80_percent, number_40_to_80_percent,
#         f0_breedings, f0_breedings_with_offspring, f1_germ_line_mice, f1_non_germ_line_mice, f1_total,
#         chimeras_with_glt, number_100_percent_glt, number_gt_50_percent_glt, number_btw_10_50_percent_glt,
#         number_lt_10_percent_glt, number_het_offspring, number_live_glt_offspring
#From mig.mir_combined_summary_with_gene
# where clone like 'EPD%'
#-- where clone in ('EPD0038_3_A02', 'EPD0019_1_A02', 'EPD0065_4_B10')

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

my $ambig_smi_ids = {
  15  => 1,
  70  => 1,
  139 => 1,
  14  => 1,
  13  => 1,
  31  => 1,
  25  => 1,
  17  => 1,
  43  => 1,
  23  => 1,
  75  => 1,
  780 => 1,
  489 => 1,
  12  => 1,
  39  => 1,
  930 => 1,
  45  => 1,
  20  => 1
};

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

      #last if ($bailout_count > 5);

      #my ($colony_name, $clone_name,$gene_id,$latest_mi_date,$number_transferred,$number_et_recipients,$number_et_recipients_np,
      #    $number_born, $number_chimeric, $male_chim, $female_chim,
      #    $num_male_100, $num_male_less_40, $num_male_gt_80, $num_male_40_80,
      #    $f0_breedings,$f0_breedings_with_offspring,$f1_germ_line_mice,$f1_non_germ_line_mice,$f1_total,
      #    $chimeras_with_glt,$number_100_percent_glt,$number_gt_50_percent_glt,$number_btw_10_50_percent_glt,
      #    $number_lt_10_percent_glt,$number_het_offspring) = map{trim ($_)} split /,/;

      # COLONY_PREFIX, CLONE,
      # GENE_NAME, MI_DATE,
      # NUMBER_TRANSFERRED, NUMBER_ET_RECIPIENTS, NUMBER_ET_RECIPIENTS_NP,
      # NUMBER_BORN, NUMBER_CHIMERIC, NUMBER_MALE, NUMBER_FEMALE,
      # NUMBER_MALE_100_PERCENT, NUMBER_MALE_LT_40_PERCENT, NUMBER_MALE_GT_80_PERCENT, NUMBER_MALE_40_TO_80_PERCENT,
      # F0_BREEDINGS, F0_BREEDINGS_WITH_OFFSPRING,
      # F1_HETS, F1_TOTAL,
      # CHIMERAS_WITH_HETS, HET_RATE_100, HET_RATE_GT_50, HET_RATE_10_TO_50, HET_RATE_LT_10,
      # ALL_MUTANT_DESCS,
      # LIVE_MUTANT_DESCS
      # FROM MIG.MIR_TO_KERMITS_MV

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

      #if ( $ambig_smi_ids->{$smi_id} ) {
      #  if ( $number_het_offspring < 10 or $number_live_glt_offspring < 0 ) {
      #    print "skipping $clone_name with ambig smi: $smi_id because het offspring < 10 or no live offspring\n";
      #    next;
      #  }
      #}

      my $emma = 0;
      if ( $number_het_offspring >= 2 && $number_live_glt_offspring > 0 ) {
        $emma = 1;
      }

      print "data: $colony_name, $clone_name, $latest_mi_date, $test_cross_jax_short_name, $back_cross_jax_short_name\n";

      next unless ($latest_mi_date);
      next unless ( $clone_name =~ /EPD/ );

      # print "colony: $colony_name clone name: $clone_name mi date  $latest_mi_date \n";

      print "accepted data: \n";

      my $clone = $schema->resultset('KermitsDB::EmiClone')->find( { clone_name => $clone_name } );

      if ( !$clone ) {
        my $well_summary_row = $eu_schema->resultset('HTGTDB::WellSummaryByDI')->find( { epd_well_name => $clone_name } );
        if ( !$well_summary_row ) {
          warn "Cant find clone in htgt called: $clone_name\n";
          next ATTEMPT;
        }
        my $project = $well_summary_row->project;
        if ( !$project ) {
          warn "Cant find project for clone: $clone_name\n";
          next ATTEMPT;
        }
        my $pipeline_id;
        if ( $project->is_eucomm ) {
          $pipeline_id = 1;
        }
        elsif ( $project->is_komp_csd ) {
          $pipeline_id = 2;
        }
        else {
          warn "dealing with clone $clone_name which is neither komp csd nor eucomm\n";
          next ATTEMPT;
        }

        my $clone_id = get_next_clone_id();

        $clone = $schema->resultset('KermitsDB::EmiClone')->create(
          {
            id           => $clone_id,
            clone_name   => $clone_name,
            gene_symbol  => $gene_name,
            pipeline_id  => $pipeline_id,
            created_date => $run_date,
            creator_id   => $creator_id,
            edited_by    => 'vvi',
            edit_date    => $run_date
          }
        );

        print "created clone: " . $clone->id . "\n";
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
      }
      else {
        my $event_id = get_next_event_id();
        $event = $schema->resultset('KermitsDB::EmiEvent')->create(
          {
            id               => $event_id,
            clone_id         => $clone->id,
            centre_id        => 1,
            proposed_mi_date => $converted_date,
            created_date     => $run_date,
            creator_id       => $creator_id,
            edited_by        => 'vvi',
            edit_date        => $run_date
          }
        );
        print "created event: " . $event->id . "\n";
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
        my $attempt_id = get_next_attempt_id();

        $attempt = $schema->resultset('KermitsDB::EmiAttempt')->create(
          {
            id                      => $attempt_id,
            production_centre_mi_id => $smi_id,
            colony_name             => $colony_name,
            event_id                => $event->id,
            is_active               => 1,
            actual_mi_date          => $converted_date,

            attempt_number => scalar(@attempts) + 1,

            num_blasts  => $number_transferred,
            number_born => $number_born,

            total_chimeras               => $number_chimeric,
            number_male_chimeras         => $male_chim,
            number_female_chimeras       => $female_chim,
            number_male_lt_40_percent    => $num_male_less_40,
            number_male_40_to_80_percent => $num_male_40_80,
            number_male_gt_80_percent    => $num_male_gt_80,
            number_male_100_percent      => $num_male_100,

            number_chimera_mated          => $f0_breedings,
            number_chimera_mating_success => $f0_breedings_with_offspring,
            number_f0_matings             => $f0_breedings,
            f0_matings_with_offspring     => $f0_breedings_with_offspring,

            total_f1_mice     => $f1_total,
            f1_germ_line_mice => $f1_germ_line_mice,

            chimeras_with_glt_from_cct     => $chimeras_with_glt,
            chimeras_with_glt_from_genotyp => undef,

            number_100_percent_glt       => $number_100_percent_glt,
            number_gt_50_percent_glt     => $number_gt_50_percent_glt,
            number_btw_10_50_percent_glt => $number_btw_10_50_percent_glt,
            number_lt_10_percent_glt     => $number_lt_10_percent_glt,

            f1_black     => $f1_black,
            f1_non_black => $f1_non_black,

            number_with_cct           => $f1_germ_line_mice,
            number_het_offspring      => $number_het_offspring,
            number_live_glt_offspring => $number_live_glt_offspring,

            emma => $emma,

            blast_strain      => $blast_jax_short_name,
            test_cross_strain => $test_cross_jax_short_name,
            back_cross_strain => $back_cross_jax_short_name,

            status_dict_id => 3,
            created_date   => $run_date,
            creator_id     => $creator_id,
            edited_by      => 'vvi',
            edit_date      => $run_date
          }
        );

        if ( $attempt->should_be_made_inactive ) {
          $attempt->update( { is_active => 0 } );
        }

        my $desired_status = $attempt->get_desired_status;
        if ( $desired_status->name eq 'Genotype Confirmed' ) {
          $attempt->update( { status_dict_id => 9 } );
        }

        print "created attempt: "
         . $attempt->id . ","
         . $attempt->is_active
         . ", $converted_date, $colony_name, $clone_name, $number_het_offspring, smi: $smi_id\n";

        #print Data::Dumper->Dump([$attempt->{_column_data}]);
      }
      else {

        #IF this is an update of an existing MI, AND that MI has been marked emma = 0 AND is_emma_sticky = 1
        # THEN we don't want to update the emma field at all.
        # print "updating: $clone_name : $colony_name emma: $emma : db emma: ".$attempt->emma." live hets: $number_live_glt_offspring\n";
        if ( $attempt->is_emma_sticky ) {
          $emma = $attempt->emma;

          # print "sticky emma - not updating emma\n";
        }
        
        #If this is a second row for the same colony, and the number of het offspring is better than what we already have
        # OR the number of live het offspring is better, then do the update. Otherwise, don't do the update.
        my $do_update = 0;
        if(
           (!$number_het_offspring && !$attempt->number_het_offspring) &&
           (!$number_live_glt_offspring && !$attempt->number_live_glt_offspring)
        ) {
           $do_update = 1;
        }elsif( $number_het_offspring && !$attempt->number_het_offspring ) {
           $do_update = 1;
        }elsif( $number_live_glt_offspring && !$attempt->number_live_glt_offspring ) {
           $do_update = 1;
        }elsif( $number_het_offspring && $number_het_offspring > $attempt->number_het_offspring ){
           $do_update = 1;
        } elsif( $number_live_glt_offspring && $number_live_glt_offspring > $attempt->number_live_glt_offspring ){
           $do_update = 1;
        }

        if($do_update){
            
            $attempt->update(
              {
    
                colony_name => $colony_name,
                num_blasts  => $number_transferred,
                number_born => $number_born,
    
                total_chimeras               => $number_chimeric,
                number_male_chimeras         => $male_chim,
                number_female_chimeras       => $female_chim,
                number_male_lt_40_percent    => $num_male_less_40,
                number_male_40_to_80_percent => $num_male_40_80,
                number_male_gt_80_percent    => $num_male_gt_80,
                number_male_100_percent      => $num_male_100,
    
                number_chimera_mated          => $f0_breedings,
                number_chimera_mating_success => $f0_breedings_with_offspring,
                number_f0_matings             => $f0_breedings,
                f0_matings_with_offspring     => $f0_breedings_with_offspring,
    
                total_f1_mice     => $f1_total,
                f1_germ_line_mice => $f1_germ_line_mice,
    
                chimeras_with_glt_from_cct     => $chimeras_with_glt,
                chimeras_with_glt_from_genotyp => undef,
    
                number_100_percent_glt       => $number_100_percent_glt,
                number_gt_50_percent_glt     => $number_gt_50_percent_glt,
                number_btw_10_50_percent_glt => $number_btw_10_50_percent_glt,
                number_lt_10_percent_glt     => $number_lt_10_percent_glt,
    
                f1_black     => $f1_black,
                f1_non_black => $f1_non_black,
    
                number_with_cct           => $f1_germ_line_mice,
                number_het_offspring      => $number_het_offspring,
                number_live_glt_offspring => $number_live_glt_offspring,
                emma                      => $emma,
    
                test_cross_strain => $test_cross_jax_short_name,
                back_cross_strain => $back_cross_jax_short_name,
                blast_strain      => $blast_jax_short_name,
    
                edited_by => 'vvi',
                edit_date => $run_date
    
              }
            );
    
            if ( $attempt->should_be_made_inactive ) {
              $attempt->update( { is_active => 0 } );
            }
    
            my $desired_status = $attempt->get_desired_status;
            if ( $desired_status->name eq 'Genotype Confirmed' ) {
              $attempt->update( { status_dict_id => 9 } );
            }
    
            print "updated attempt: "
             . $attempt->id . ","
             . $attempt->is_active
             . ", $converted_date, $colony_name, $clone_name, $number_het_offspring, smi: $smi_id, "
             . $desired_status->name . "\n";
    
            # print Data::Dumper->Dump([$attempt->{_column_data}]);
        }else{
            print "did NOT update emi_attempt - het offspring (${number_het_offspring}) or live_mutant_offspring (${number_live_glt_offspring}) did not increase\n";
        }
      }
}#End While

sub get_next_clone_id {
  my $id;
  my $sth = $schema->storage->dbh->prepare('select EMI_CLONE_SEQ.nextval from dual');
  $sth->execute();
  while ( my @result = $sth->fetchrow_array ) {
    $id = $result[0];
  }
  return $id;
}

sub get_next_event_id {
  my $id;
  my $sth = $schema->storage->dbh->prepare('select EMI_EVENT_SEQ.nextval from dual');
  $sth->execute();
  while ( my @result = $sth->fetchrow_array ) {
    $id = $result[0];
  }
  return $id;
}

sub get_next_attempt_id {
  my $id;
  my $sth = $schema->storage->dbh->prepare('select EMI_ATTEMPT_SEQ.nextval from dual');
  $sth->execute();
  while ( my @result = $sth->fetchrow_array ) {
    $id = $result[0];
  }
  return $id;
}

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
