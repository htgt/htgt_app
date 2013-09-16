#!/usr/bin/env perl

use strict;
use Getopt::Long;

use Data::Dumper;
use HTGT::DBFactory;
use HTGT::BioMart::QueryFactory;
use DateTime;
use DateTime::Format::Builder;
use DateTime::Format::Flexible;
use Date::Format;
use iMits;
use Log::Log4perl qw(:easy);

use DBI;



#$| = 1;

my $clone_name;
my $discrepancy_check;
my $dry_run;
my $live;

GetOptions(
    'clone_name:s'  => \$clone_name,
    'discrepancy_check' => \$discrepancy_check,
    'dry_run' => \$dry_run,
    'live' => \$live
);

if($discrepancy_check){
  print "#### DISCREPANCY CHECK!!\n" if($discrepancy_check);
  $dry_run = 1;
}
print "#### DRY-RUN!!\n" if($dry_run);

my $eu_schema = HTGT::DBFactory->connect('eucomm_vector');

my $mig_dbh   = HTGT::DBFactory::DBConnect->dbi_connect('mig');

Log::Log4perl->easy_init({level => $DEBUG});

my $dbh; my $imits;
my $base_url;

if($live){
  print "CONNECTING TO LIVE iMits DATABASE\n";
  $dbh = DBI->connect('dbi:Pg:database=imits_combined;host=imits-db;port=5433','imits','xei:x&ahCh4c');
  $base_url = "http://t87-apache.internal.sanger.ac.uk:8000/imits/";
  $imits = iMits->new(
      username  => 'htgt@sanger.ac.uk',
      base_url  => $base_url,
      password  => 'WPbjGHdG'
  );
}else{
  print "CONNECTING TO TEST staging DATABASE\n";
  $dbh = DBI->connect('dbi:Pg:database=imits_test;host=imits-db;port=5434','imits','imits');
  $base_url = "http://www.i-dcc.org/staging/imits";
  $imits = iMits->new(
      username  => 'htgt@sanger.ac.uk',
      base_url  => 'http://www.i-dcc.org/staging/imits/',
      password  => 'password',
  );
}

# This select pulls up the es cell pipeline for a single clone
my $es_cell_pipeline_sth = $dbh->prepare( qq[
  select targ_rep_pipelines.name
  from 
  targ_rep_es_cells join targ_rep_pipelines
  on targ_rep_es_cells.pipeline_id = targ_rep_pipelines.id
  where targ_rep_es_cells.name = ? 
]);

# This select is used to fetch the MGI-accession for 
# an input clone directly from tarmits itself.
# 
my $clone_sth = $dbh->prepare (qq[
  select genes.mgi_accession_id, name 
  from genes join targ_rep_alleles on genes.id = targ_rep_alleles.gene_id
  join targ_rep_es_cells on targ_rep_alleles.id = targ_rep_es_cells.allele_id 
  where name = ?
]);

#This select is used to find WTSI-related consortia
# when a new MI has to be created
my $consortium_sth = $dbh->prepare(qq [
  select distinct consortia.name
  from mi_plans join genes on mi_plans.gene_id = genes.id
  join consortia on mi_plans.consortium_id = consortia.id
  join mi_plan_statuses on mi_plan_statuses.id = mi_plans.status_id
  where mgi_accession_id  = ?
  and consortia.name in ('MGP','BaSH','EUCOMMToolsCre')
]);

my $mi_plans_sth = $dbh->prepare(qq [
  select distinct consortia.name, mi_plans.id
  from mi_plans join genes on mi_plans.gene_id = genes.id
  join consortia on mi_plans.consortium_id = consortia.id
  join centres on mi_plans.production_centre_id = centres.id
  join mi_plan_statuses on mi_plan_statuses.id = mi_plans.status_id
  where mgi_accession_id  = ?
  and consortia.name in ('MGP','BaSH','EUCOMMToolsCre')
  and centres.name = 'WTSI'
  and mi_plans.phenotype_only = false
]);

my $update_data_to_resultset_map = {
  #mi start data
  'workflow_pipeline'=>'WORKFLOW_PIPELINE',
  'colony_name'=>'COLONY_PREFIX',
  'es_cell_name'=>'CLONE',
  'mi_date'=>'MI_DATE',
  'blast_strain_name'=>'BLAST_JAX_NAME',
  'total_transferred'=>'NUMBER_TRANSFERRED',
  'total_pups_born' => 'NUMBER_BORN',
  'total_male_chimeras' => 'NUMBER_MALE',
  'total_female_chimeras' => 'NUMBER_FEMALE',

  #chimera breeding data
  'test_cross_strain_name'=>'TEST_CROSS_JAX_NAME',
  'number_of_males_with_100_percent_chimerism'=>'NUMBER_MALE_100_PERCENT',
  'number_of_males_with_80_to_99_percent_chimerism'=>'NUMBER_MALE_GT_80_PERCENT',
  'number_of_males_with_0_to_39_percent_chimerism'=>'NUMBER_MALE_LT_40_PERCENT',
  'number_of_males_with_40_to_59_percent_chimerism'=>'NUMBER_MALE_40_TO_60_PERCENT',
  'number_of_males_with_60_to_79_percent_chimerism'=>'NUMBER_MALE_60_TO_80_PERCENT',
  #'number_of_males_with_40_to_79_percent_chimerism'=>'NUMBER_MALE_40_TO_80_PERCENT',
  'number_of_chimera_matings_attempted'=>'F0_BREEDINGS',
  'number_of_chimera_matings_successful'=>'F0_BREEDINGS_WITH_OFFSPRING',

  #f1 breeding data
  'total_f1_mice_from_matings'=>'F1_TOTAL',
  'colony_background_strain_name'=>'BACKCROSS_JAX_NAMES',
  'number_of_chimeras_with_glt_from_genotyping'=>'CHIMERAS_WITH_HETS',
  'number_of_chimeras_with_100_percent_glt'=>'HET_RATE_100',
  'number_of_chimeras_with_50_to_99_percent_glt'=>'HET_RATE_GT_50',
  'number_of_chimeras_with_10_to_49_percent_glt'=>'HET_RATE_10_TO_50',
  'number_of_chimeras_with_0_to_9_percent_glt'=>'HET_RATE_LT_10',
  'number_of_het_offspring'=>'ALL_MUTANT_DESCENDENTS',
  'number_of_live_glt_offspring'=>'LIVE_MUTANT_DESCENDENTS',

  'genotyping_comment'=>'GENOTYPING_ADD_INFO',
};


my $clone_sql_piece = '';
if ($clone_name){
    $clone_sql_piece = " and clone = '$clone_name' ";
}

my $read_mig_data_sql = qq [
select
    scheduled_micro_injection_id, colony_prefix, clone, gene_name, mi_date,
    number_transferred, number_et_recipients, number_et_recipients_np,
    number_born, number_chimeric, number_male, number_female,
    number_male_100_percent, number_male_lt_40_percent, number_male_gt_80_percent,
    number_male_40_to_60_percent,
    number_male_60_to_80_percent,
    f0_breedings, f0_breedings_with_offspring,
    f1_hets, f1_total,
    chimeras_with_hets, het_rate_100, het_rate_gt_50, het_rate_10_to_50, het_rate_lt_10,
    ALL_MUTANT_descendents,
    LIVE_MUTANT_descendents,
    test_cross_jax_name,
    backcross_jax_names,
    blast_jax_name,
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
    neo_short_range_pcr,
    released_from_genotyping,
    genotyping_add_info,
    workflow_pipeline
    from
    mig.mir_to_kermits_mv
    where workflow_pipeline in ('MGP', 'PMGP', 'MGP-BaSH', 'EUCOMMTools','MGP-EUMODIC','MGP-Bespoke','MGP-KOMP1','PMGP-KOMP1','PMGP-EUMODIC','MGP-Bespoke','EUCOMMTools+DreESC')
    $clone_sql_piece
];

DEBUG ("$read_mig_data_sql");

my $sth = $mig_dbh->prepare($read_mig_data_sql);
$sth->execute();

DEBUG("executed sql");

#hashref of arrayrefs.
#keys - colony prefixes (e.g. MAHN etc.), values - arrayref of same-colony resultset rows
my $mouse_colonies;
my $best_mouse_colonies;

DEBUG("starting row gather");

#gather up rows representing the same colony by colony prefix
while ( my $resultset_row = $sth->fetchrow_hashref() ) {
  next unless $resultset_row->{CLONE} =~ /EPD/;

  #next unless $resultset_row->{COLONY_PREFIX} =~ /MEWH/;
  #print Dumper(\$resultset_row);

  accumulate_row( $resultset_row);
}

DEBUG("choosing best row");

#choose the best row from the set gathered
foreach my $colony_prefix (keys %{$mouse_colonies}){
  my $row = pick_best_row ( $colony_prefix, $mouse_colonies->{$colony_prefix} );
  $best_mouse_colonies->{$colony_prefix} = $row;
}

DEBUG("found ".scalar(keys %{$mouse_colonies})." distinct colonies");
DEBUG("performing update to imits");

#use the best row to perform the update
foreach my $colony_prefix (keys %{$best_mouse_colonies}){
  #First snag all the update data as a 'pure' hash with attributes which are all in imits
  my $update_data = make_update_data ( $best_mouse_colonies->{$colony_prefix} );
  if($colony_prefix eq 'MCGB'){
    $update_data->{colony_background_strain_name} = 'C57BL/6NTac/Den';
  }
  next unless ($update_data->{es_cell_name} && $update_data->{mi_date});
  create_or_update_imits ( $update_data );
}

sub accumulate_row {
  my $resultset_row = shift;
  my $colony_prefix = $resultset_row->{COLONY_PREFIX};
  if(!$colony_prefix){
    warn "no colony prefix for row with smi-id: ". $resultset_row->{SCHEDULED_MICRO_INJECTION_ID};
    return;
  }elsif(!$resultset_row->{MI_DATE}){
    warn "no mi date for row with smi-id: ". $resultset_row->{SCHEDULED_MICRO_INJECTION_ID};
  }else{
    my $accumulated_colonies = $mouse_colonies->{$colony_prefix};
    if(!$accumulated_colonies){
      $accumulated_colonies = [];
    }
    push @{$accumulated_colonies}, $resultset_row;
    $mouse_colonies->{$colony_prefix} = $accumulated_colonies;
  }
}

sub pick_best_row {
  my $colony_prefix = shift;
  my $rows_for_colony = shift;
  my @rows = @{$rows_for_colony};
  my $returned_row;
  if(scalar(@rows)==1){
    $returned_row = $rows[0];
  }else{
    #Any row which is released from genotyping is better than a row which isn't
    DEBUG("resolving multiple rows for colony $colony_prefix");
    my @released = grep {$_->{RELEASED_FROM_GENOTYPING} eq 'Yes'} @rows;
    if(@released){
      if(scalar(@released) > 1){
        my @released_and_chimeric = grep {$_->{NUMBER_MALE} > 0} @released;
        if(scalar(@released_and_chimeric) > 0){
          $returned_row = $released_and_chimeric[0];
          DEBUG("found a released from genotyping row WITH chimeric resolution!");
        }else{
          $returned_row = $released[0];
          DEBUG("found a released from genotyping row without chimeric resolution!");
        }
      }else{
          $returned_row = $released[0];
      }
    }else{
      # Any row which has hets is better than a row which isn't
      # Any row which has chimeras is better than a row which hasn't
      my @sorted_rows =
        sort {
          ($b->{ALL_MUTANT_DESCENDENTS} <=> $a->{ALL_MUTANT_DESCENDENTS}) ||
          ($b->{NUMBER_CHIMERIC} <=> $a->{NUMBER_CHIMERIC}) ||
          ($b->{SCHEDULED_MICRO_INJECTION_ID} <=> $a->{SCHEDULED_MICRO_INJECTION_ID})
        } @rows;

      $returned_row = shift @sorted_rows;
    }
  }
  return $returned_row;
}

sub has_distribution_centre {
  my $mi = shift;
  return $mi && $mi->{distribution_centres_attributes} && scalar(@{$mi->{distribution_centres_attributes}}) > 0 ;
}

sub update_imits_colony {
  my $mi = shift;
  my $update_data = shift;
  my $colony = $update_data->{colony_name};
  my $mi_id = $mi->{id};
  
  my $new_release = 'not new';
  my $suppress = 'keep';
  if(!$mi->{is_released_from_genotyping} && ($update_data->{is_released_from_genotyping} eq 'true')){
    $new_release = 'new release';
  }
  if(
     ($mi->{status_name} eq 'Genotype confirmed' && $mi->{is_active} eq 'true')
     && ($update_data->{is_active} eq 'false')
  ){
    $suppress = 'suppress';
  }

  my $dist_centre_name = "";
  
  if($mi->{status_name} eq 'Genotype confirmed') {
	  
    # If the colony is GC and its colony bg is missing,
    # then default the test-cross strain if it's there
    add_missing_background_from_test($update_data);

    if(!has_distribution_centre($mi)) {
      my %new_hash;

      my $es_cell_name = $update_data->{es_cell_name};
      my $es_cell_pipeline = get_es_cell_pipeline($es_cell_name);

      $dist_centre_name = "WTSI";
      $new_hash{'centre_name'} = 'WTSI';
      $new_hash{'deposited_material_name'} = 'Live mice';
      if($es_cell_pipeline =~ /EUCOMM/){
        $new_hash{'distribution_network'} = 'EMMA'; 
      }
      push @{$update_data->{distribution_centres_attributes}}, \%new_hash if %new_hash;
    }
  }
  
  DEBUG(
    "update ".$mi->{consortium_name}.",$colony, ".$mi->{es_cell_name}.",".$mi->{mi_date}."(,".$update_data->{mi_date}."), old rg,".
    $mi->{is_released_from_genotyping}.",old status,".$mi->{status_name}.
    ",new rg,".
    $update_data->{is_released_from_genotyping}.",old active,".$mi->{is_active}.
    ",new active,".$update_data->{is_active}.",$new_release,$suppress,".
    $update_data->{blast_strain_name}.",".
    $update_data->{test_cross_strain_name}.",".
    $update_data->{colony_background_strain_name}.",".
    $mi->{number_of_chimera_matings_attempted}.",".
    $update_data->{number_of_chimera_matings_attempted}.",".
    $mi->{number_of_live_glt_offspring}.",".
    $update_data->{number_of_live_glt_offspring},
    $dist_centre_name
  );

  if(!$dry_run){
    eval{
      $imits->update_mi_attempt($mi_id, $update_data);
    };
    if ($@) {
      WARN ($@);
      return;
    }
  }else{
    DEBUG ("no update - dry run\n");
  }
}

sub get_es_cell_pipeline{
  my $es_cell_name = shift;
  $es_cell_pipeline_sth->execute($es_cell_name);
  my $pipeline;
  while(my @results= $es_cell_pipeline_sth->fetchrow_array()){
    return $results[0];
  }
}

sub create_new_imits_colony {
  my $update_data = shift;
  my $colony = $update_data->{colony_name};

  # Deduce the required consortium based on the workflow pipeline 
  # If imits has exactly one plan based on the required consortium,
  # Then create the MI for that plan. Otherwise warn and move on 

  my $mgi_acc =  get_mgi_acc_for_clone($update_data->{es_cell_name});

  my @existing_wtsi_plans_and_ids = @{get_WTSI_plans_and_ids_for_new_MI($mgi_acc)};
  
  
  if(!(@existing_wtsi_plans_and_ids)){
    warn "NO WTSI MI Plans found for MI / clone: ".$update_data->{es_cell_name}."\n";
  }

  my $chosen_consortium;
  my $workflow_pipeline = $update_data->{workflow_pipeline};

  if($workflow_pipeline eq 'EUCOMMTools' || $workflow_pipeline eq 'EUCOMMTools+DreESC' ){
    $chosen_consortium = 'EUCOMMToolsCre';
  }elsif($workflow_pipeline eq 'MGP' || $workflow_pipeline eq 'PMGP' || $workflow_pipeline eq 'MGP-EUMODIC' || 
	  $workflow_pipeline eq 'MGP-Bespoke'|| $workflow_pipeline eq 'MGP-KOMP1' || $workflow_pipeline eq 'PMGP-KOMP1' ||
	  $workflow_pipeline eq 'PMGP-EUMODIC'|| $workflow_pipeline eq 'MGP-Bespoke' 
  ){
    $chosen_consortium = 'MGP';
  }elsif($workflow_pipeline eq 'MGP-BaSH'){
    $chosen_consortium = 'BaSH';
  }else{
    die "unrecognised workflow pipeline: $workflow_pipeline\n";
  }

  my @chosen_plan_ids;
  my @existing_WTSI_consortia;
  foreach my $unit (@existing_wtsi_plans_and_ids){
    my $consortium = $unit->[0];
    push @existing_WTSI_consortia, $consortium;
    my $plan_id = $unit->[1];
    if($consortium eq $chosen_consortium){
      push @chosen_plan_ids, $plan_id;
    }
  }

  if (!@chosen_plan_ids){
    WARN ( "There are no possible $chosen_consortium plans for for MI / clone: $mgi_acc - (existing consortia are @existing_WTSI_consortia )  - new one will NOT be created with MI attempt");
    return;
  }
  if (scalar(@chosen_plan_ids) > 1){
    WARN ( "There are too many possible plans for MI / clone ($mgi_acc): [@chosen_plan_ids]\n" );
    return;
  }

  my $chosen_plan_id = $chosen_plan_ids[0];
  $update_data->{mi_plan_id} = $chosen_plan_ids[0];

  print "Chose consortium $chosen_consortium, plan $chosen_plan_id for new MI\n";

  if(!$dry_run){

    my $new_mi = undef;
    eval{
      $new_mi = $imits->create_mi_attempt($update_data);
    };
    if ($@) {
      WARN ($@);
      return;
    }

    DEBUG("new mi created for consortium / epd / midate,".$new_mi->{consortium_name}.",".$update_data->{es_cell_name}.",".$update_data->{mi_date}.",$colony,id ".$new_mi->{id});

  }else{
    DEBUG("no new mi created - dry run - for epd / midate,".$update_data->{es_cell_name}.",".$update_data->{mi_date}.",$colony,");
  }
}

sub do_discrepancy_check {
  my ($mi, $update_data) = @_;
  my $new_workflow_pipeline = $update_data->{workflow_pipeline};
  my $new_es_cell_name = $update_data->{es_cell_name};
  my $old_consortium = $mi->{consortium_name};
  
  if($old_consortium eq 'MGP Legacy'){
    $old_consortium = 'MGP';
  }
  if($old_consortium eq 'EUCOMM-EUMODIC'){
    $old_consortium = 'MGP';
  }
  
  my $es_cell_name = $mi->{es_cell_name};
  my $expected_consortium = 'MGP';
  
  if($new_workflow_pipeline =~ /BaSH/i){
    $expected_consortium = 'BaSH';
  }
  if($new_workflow_pipeline =~ /Tools/i){
    $expected_consortium = 'EUCOMMToolsCre';
  }
  if(
     !($expected_consortium =~ /$old_consortium/)
  ){
    WARN "DISCREPANCY - CONSORTIUM,".$mi->{colony_name}.",$mi->{status_name},$mi->{mi_date},$old_consortium,$new_workflow_pipeline,$expected_consortium,$es_cell_name,$new_es_cell_name\n";
  }
  if(
     !($new_es_cell_name eq $es_cell_name) 
  ){
    WARN "DISCREPANCY - ESCELL,".$mi->{colony_name}.",$mi->{status_name},$mi->{mi_date},$old_consortium,$expected_consortium,$es_cell_name,$new_es_cell_name\n";
  } 
}

sub create_or_update_imits {
  my $update_data = shift;
  my $colony = $update_data->{colony_name};

  my @search_result = @{$imits->find_mi_attempt({ colony_name_eq => $colony })};
  if(@search_result > 1){
    
    die "found two rows with same colony identifier: $colony\n";
    
  }elsif(@search_result == 1){
    
    my $mi = $search_result[0];
    die "returned search record for colony $colony has no internal id\n" unless $mi->{id};
    
    if($discrepancy_check){
      do_discrepancy_check($mi, $update_data);
      return;
    }
    
    update_imits_colony($mi, $update_data);

  }else{
    
    create_new_imits_colony($update_data);
  }

}


sub make_update_data {
  my $row = shift;
  my $update_data = {};

  while (my ($key, $value) = each %{$update_data_to_resultset_map}){
    make_update_field_if_defined($key,$update_data,$value,$row);
  }

  #Compose two of the chimerism bins into a single bin
  convert_chimerism_bins($update_data);

  convert_mi_date($update_data);

  make_qc_update_data($row, $update_data);


  return $update_data;
}

sub add_missing_background_from_test {
  my $update_data = shift;
  my $background = $update_data->{colony_background_strain_name};
  if(!$background){
    DEBUG "Setting missing colony bg strain with test_cross strain ".$update_data->{test_cross_strain_name}."\n";
    $update_data->{colony_background_strain_name} = $update_data->{test_cross_strain_name};
  }
}

sub convert_chimerism_bins{
  my $update_data = shift;
  my $a = $update_data->{number_of_males_with_40_to_59_percent_chimerism};
  my $b = $update_data->{number_of_males_with_60_to_79_percent_chimerism};
  $update_data->{number_of_males_with_40_to_79_percent_chimerism} = $a + $b;
  $update_data->{total_male_chimeras} =
	($update_data->{number_of_males_with_0_to_39_percent_chimerism}||0) +
	($update_data->{number_of_males_with_40_to_79_percent_chimerism}||0) +
	($update_data->{number_of_males_with_80_to_99_percent_chimerism}||0) +
	($update_data->{number_of_males_with_100_percent_chimerism}||0);

  delete $update_data->{number_of_males_with_40_to_59_percent_chimerism};
  delete $update_data->{number_of_males_with_60_to_79_percent_chimerism};
}

sub convert_mi_date {
  my $update_data = shift;
  my $old_mi_date = $update_data->{mi_date};
  die "update data has no mi date" unless $old_mi_date;
  my $mi_date = DateTime::Format::Flexible->parse_datetime( $old_mi_date );
  my $converted_date = $mi_date->strftime("%Y-%m-%d");
  $update_data->{mi_date} = $converted_date;
}

sub latest_mi_date_too_far_past {
  my $input_mi_date = shift;
  my $now = DateTime->now();
  my $mi_date = DateTime::Format::Flexible->parse_datetime( $input_mi_date );
  my $diff = $now->delta_md($mi_date);
  $diff = $diff->delta_months;
  if($diff && ($diff > 9)){
    return 1;
  }else{
    return 0;
  }
}


sub make_qc_update_data {
  my $row = shift;
  my $update_data = shift;

  # All state transition is left to the server code (to be determined by data passed in)
  # Here we only work out whether to explicitly INACTIVE an MI. We will do this if  the
  # raw value of released from genotyping is 'Line abandoned'.
  # ALSO, if no progress has been made on an MI for 9 months, then we inactivate it
  my $make_inactive = 0;
  my $released_from_genotyping = $row->{RELEASED_FROM_GENOTYPING};
  my $latest_mi_date          = $row->{MI_DATE};

  $update_data->{is_released_from_genotyping} = 'false';

  if($released_from_genotyping eq 'Yes'){
    $update_data->{is_released_from_genotyping} = 'true';
  }elsif($released_from_genotyping eq 'Line abandoned') {
    $update_data->{is_active} = 'false';
  }elsif(latest_mi_date_too_far_past($latest_mi_date)){
    $update_data->{is_active} = 'false';
  }

  my $qc_five_prime_lr_pcr = convert_mig_pass($row->{FIVE_LR_PCR});
  $update_data->{qc_five_prime_lr_pcr_result} = $qc_five_prime_lr_pcr;

  my $qc_three_prime_lr_pcr = convert_mig_pass($row->{THREE_LR_PCR});
  $update_data->{qc_three_prime_lr_pcr_result} = $qc_three_prime_lr_pcr;

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
  $update_data->{qc_tv_backbone_assay_result} = $qc_tv_backbone_assay;

  my $qc_loxp_confirmation = convert_mig_pass($row->{LOXP_PCR_WORKS});
  $update_data->{qc_loxp_confirmation_result} = $qc_loxp_confirmation;

  my $qc_loa_qpcr = convert_mig_pass($row->{LOSS_OF_WT_ALLELE_QPCR});
  $update_data->{qc_loa_qpcr_result} = $qc_loa_qpcr;

  my $qc_homozygous_loa_sr_pcr = convert_mig_pass($row->{HOMS_CONFIRMED_BY_SRPCR});
  $update_data->{qc_homozygous_loa_sr_pcr_result} = $qc_homozygous_loa_sr_pcr;

  my $qc_neo_count_qpcr = convert_mig_pass($row->{NEO_COUNT_CORRECT});
  $update_data->{qc_neo_count_qpcr_result} = $qc_neo_count_qpcr;

  my $qc_mutant_specific_sr_pcr = convert_mig_pass($row->{MUTANT_PCR_ASSAY_WORKS});
  $update_data->{qc_mutant_specific_sr_pcr_result} = $qc_mutant_specific_sr_pcr;

  my $qc_lacz_sr_pcr = convert_mig_pass($row->{LACZ_SRPCR_WORKS});
  $update_data->{qc_lacz_sr_pcr_result} = $qc_lacz_sr_pcr;

  my $qc_five_prime_cassette_integrity_result = convert_mig_pass($row->{FIVE_FRT_SRPCR_WORKS});
  $update_data->{qc_five_prime_cassette_integrity_result} = $qc_five_prime_cassette_integrity_result;

  my $qc_neo_sr_pcr = convert_mig_pass($row->{NEO_SHORT_RANGE_PCR});
  $update_data->{qc_neo_sr_pcr_result} = $qc_neo_sr_pcr;
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

sub make_update_field_if_defined {
  my $update_field_name = shift;
  my $update_data = shift;
  my $rs_field_name = shift;
  my $row = shift;

  if(defined $row->{$rs_field_name}){$update_data->{$update_field_name} = $row->{$rs_field_name}};
}

sub get_WTSI_consortium_name_for_new_MI {
  my $mgi_acc = shift;
  $consortium_sth->execute($mgi_acc);
  my $return_arrayref = [];
  while(my @results= $consortium_sth->fetchrow_array()){
    push @{$return_arrayref},$results[0];
  }
  return $return_arrayref;
}

sub get_WTSI_plans_and_ids_for_new_MI {
  my $mgi_acc = shift;
  $mi_plans_sth->execute($mgi_acc);
  my $return_arrayref = [];
  while(my @results= $mi_plans_sth->fetchrow_array()){
    my $unit;
    $unit->[0] = $results[0];
    $unit->[1] = $results[1];
    push @{$return_arrayref},$unit;
  }
  return $return_arrayref;
}

sub get_mgi_acc_for_clone {
  my $clone_name = shift;
  print "NEW CLONE NAME $clone_name\n";
  $clone_sth->execute($clone_name);
  my $return_arrayref = [];
  while(my @results= $clone_sth->fetchrow_array()){
    print "RETURNING MGI: ".$results[0]."\n";
    return $results[0];
  }

  warn "no mgi gene found in targrep for clone $clone_name\n";
  return undef;
}
