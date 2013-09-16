#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use Const::Fast;
use CSV::Writer;

const my $EPD_SUMMARY_QUERY => <<'EOT';
select
  epd_plate_name,
  marker_symbol,
  mgi_accession_id,  
  design_id,
  design_plate_name,
  parent_plate_name,
  sum(distributed) conditionals,
  sum(targ_trap) targ_traps,
  sum(distributed) + sum(targ_trap) targeted
from
  (
  select
    epd_plate_name,
    mgi_gene.marker_symbol,
    mgi_gene.mgi_accession_id,
    project.design_id,
    project.design_plate_name,
    parent_plate.name parent_plate_name,
    decode(well_summary_by_di.epd_distribute, 'yes', 1, 0) distributed,
    decode(well_summary_by_di.targeted_trap, 'yes', 1, 0) targ_trap
  from
   mgi_gene
   join project
     on project.mgi_gene_id = mgi_gene.mgi_gene_id
   join well_summary_by_di
     on well_summary_by_di.project_id = project.project_id
   join well epd_well
     on epd_well.well_id = well_summary_by_di.epd_well_id     
   join well parent_well
     on parent_well.well_id = epd_well.parent_well_id
   join plate parent_plate
     on parent_plate.plate_id = parent_well.plate_id
  where
    epd_plate_name is not null
  )
  group by
    epd_plate_name,
    marker_symbol,
    mgi_accession_id,
    design_id,
    design_plate_name,
    parent_plate_name
  order by
    epd_plate_name
EOT

my $csv = CSV::Writer->new;

my $dbh = HTGT::DBFactory->dbi_connect( 'eucomm_vector' );
my $sth = $dbh->prepare( $EPD_SUMMARY_QUERY );
$sth->execute;

$csv->set_columns( $sth->{NAME_lc} );
$csv->write( $csv->columns );

while ( my $datum = $sth->fetchrow_hashref( 'NAME_lc' ) ) {
    $csv->write( $datum );
}
