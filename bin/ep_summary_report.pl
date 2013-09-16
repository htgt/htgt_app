#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use Const::Fast;
use CSV::Writer;

const my $EP_SUMMARY_QUERY => <<'EOT';
select
  marker_symbol,
  mgi_accession_id,
  ensembl_gene_id,
  vega_gene_id,
  is_eucomm,
  is_eucomm_tools,
  is_eucomm_tools_cre,
  is_komp_csd,
  is_eutracc,
  is_switch,
  is_tpp,
  is_mgp_bespoke,
  design_id,
  cassette,
  backbone,
  pgdgr_plate_name,
  pgdgr_well_name,
  pgdgr_well_id,
  pgdgr_distribute,
  pg_pass_level,
  parent_plate_name,
  parent_well_name,
  parent_well_id,
  ep_plate_name,
  ep_well_name,
  es_cell_line,
  total_colonies,
  colonies_picked,
  ep_well_id,
  report_date,
  edit_date,
  (  select count (distinct(epd_well.well_id))
     from well epd_well
     where epd_well.parent_well_id = ep_well_id
  ) colonies_screened,
  conditionals,
  targ_traps,
  targeted,
  deletion_size,
  GF3_LAR2,
  GF3_LAR3,
  GF3_LAR5,
  GF3_LAR7,
  GF3_LAVI,
  GF4_LAR2,
  GF4_LAR3,
  GF4_LAR5,
  GF4_LAR7,
  GF4_LAVI,
  JOEL2_GR3,
  JOEL2_GR4,
  FRTL3_GR3,
  FRTL3_GR4,
  LF_GR3,
  LF_GR4
from (
  select
    marker_symbol,
    mgi_accession_id,
    ensembl_gene_id,
    vega_gene_id,
    is_eucomm,
    is_eucomm_tools,
    is_eucomm_tools_cre,
    is_komp_csd,
    is_eutracc,
    is_switch,
    is_tpp,
    is_mgp_bespoke,
    design_id,
    cassette,
    backbone,
    pgdgr_plate_name,
    pgdgr_well_name,
    pgdgr_well_id,
    pgdgr_distribute,
    pg_pass_level,
    parent_plate_name,
    parent_well_name,
    parent_well_id,
    ep_plate_name,
    ep_well_name,
    es_cell_line,
    total_colonies,
    colonies_picked,
    ep_well_id,
    report_date,
    max(ep_well_edit_date) edit_date,
    sum(distributed) conditionals,
    sum(targ_trap) targ_traps,
    sum(distributed) + sum(targ_trap) targeted,
    (  select max (feature_start)-MIN(feature_end)-1 deletion_size
       from feature, feature_type_dict, feature_data
       where feature.feature_id = feature_data.feature_id
       and feature.feature_type_id = feature_type_dict.feature_type_id
       and feature_type_dict.description in ('U5','D3')
       and feature_data.feature_data_type_id = 3
       and feature.design_id = project_design_id
    ) deletion_size,
  GF3_LAR2,
  GF3_LAR3,
  GF3_LAR5,
  GF3_LAR7,
  GF3_LAVI,
  GF4_LAR2,
  GF4_LAR3,
  GF4_LAR5,
  GF4_LAR7,
  GF4_LAVI,
  JOEL2_GR3,
  JOEL2_GR4,
  FRTL3_GR3,
  FRTL3_GR4,
  LF_GR3,
  LF_GR4
  from (
    select
      mgi_gene.marker_symbol,
      mgi_gene.mgi_accession_id,
      mgi_gene.ensembl_gene_id,
      mgi_gene.vega_gene_id,
      project.is_eucomm,
      project.is_eucomm_tools,
      project.is_eucomm_tools_cre,
      project.is_komp_csd,
      project.is_eutracc,
      project.is_switch,
      project.is_tpp,
      project.is_mgp_bespoke,
      project.design_id,
      project.cassette,
      project.backbone,
      project.design_id project_design_id,
      well_summary_by_di.pgdgr_plate_name,
      well_summary_by_di.pgdgr_well_name,
      well_summary_by_di.pgdgr_well_id,
      well_summary_by_di.pgdgr_distribute,
      well_summary_by_di.pg_pass_level,
      parent_plate.name parent_plate_name,
      parent_well.well_name parent_well_name,
      parent_well.well_id parent_well_id,
      ep_well.edit_date ep_well_edit_date,
      plate_data.data_value report_date,
      well_summary_by_di.ep_well_id,
      well_summary_by_di.ep_plate_name,
      well_summary_by_di.ep_well_name,
      well_summary_by_di.es_cell_line,
      well_summary_by_di.total_colonies,
      well_summary_by_di.colonies_picked,
      decode(well_summary_by_di.epd_distribute, 'yes', 1, 0) distributed,
      decode(well_summary_by_di.targeted_trap, 'yes', 1, 0) targ_trap,
      GF3_LAR2,
      GF3_LAR3,
      GF3_LAR5,
      GF3_LAR7,
      GF3_LAVI,
      GF4_LAR2,
      GF4_LAR3,
      GF4_LAR5,
      GF4_LAR7,
      GF4_LAVI,
      JOEL2_GR3,
      JOEL2_GR4,
      FRTL3_GR3,
      FRTL3_GR4,
      LF_GR3,
      LF_GR4
   from
     mgi_gene
     join project
       on project.mgi_gene_id = mgi_gene.mgi_gene_id
     join well_summary_by_di
       on well_summary_by_di.project_id = project.project_id
     join well ep_well
       on ep_well.well_id = well_summary_by_di.ep_well_id     
     join well parent_well
       on parent_well.well_id = ep_well.parent_well_id
     join plate parent_plate
       on parent_plate.plate_id = parent_well.plate_id
     left outer join plate_data
       on plate_data.plate_id = ep_well.plate_id
      and plate_data.data_type = 'report_date'
     left outer join primer_band_size
       on primer_band_size.project_id = project.project_id
   where
     ep_plate_name is not null
  )
  group by
    marker_symbol,
    mgi_accession_id,
    ensembl_gene_id,
    vega_gene_id,
    design_id,
    cassette,
    backbone,
    is_eucomm,
    is_eucomm_tools,
    is_eucomm_tools_cre,
    is_komp_csd,
    is_eutracc,
    is_switch,
    is_tpp,
    is_mgp_bespoke,
    pgdgr_plate_name,
    pgdgr_well_name,
    pgdgr_well_id,
    pgdgr_distribute,
    pg_pass_level,
    parent_plate_name,
    parent_well_name,
    parent_well_id,
    ep_plate_name,
    ep_well_name,
    es_cell_line,
    total_colonies,
    colonies_picked,
    ep_well_id,
    report_date,
    GF3_LAR2,
    GF3_LAR3,
    GF3_LAR5,
    GF3_LAR7,
    GF3_LAVI,
    GF4_LAR2,
    GF4_LAR3,
    GF4_LAR5,
    GF4_LAR7,
    GF4_LAVI,
    JOEL2_GR3,
    JOEL2_GR4,
    FRTL3_GR3,
    FRTL3_GR4,
    LF_GR3,
    LF_GR4
  )
order by ep_plate_name, ep_well_name
EOT

my $csv = CSV::Writer->new;

my $dbh = HTGT::DBFactory->dbi_connect( 'eucomm_vector' );
my $sth = $dbh->prepare( $EP_SUMMARY_QUERY );
$sth->execute;

$csv->set_columns( $sth->{NAME_lc} );
$csv->write( $csv->columns );

while ( my $datum = $sth->fetchrow_hashref( 'NAME_lc' ) ) {
    if ( $datum->{report_date} ) {
        $datum->{report_date} =~ s/^\d+-//; # display only month and year
    }
    $csv->write( $datum );
}
