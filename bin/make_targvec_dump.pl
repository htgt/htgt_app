#!/usr/bin/env perl

use strict;
use Getopt::Long;
use Data::Dumper;
use HTGT::DBFactory;

my $debug;
my $verbose;
my $help;

GetOptions(
    'debug|d'      => \$debug,
    'verbose|v'    => \$verbose,
    'help|?'       => \$help,
);

## Catch calls for help!

if ( $help || ( defined $ARGV[0] && $ARGV[0] =~ /\?|help/ ) ) {
    show_help();
    exit;
}

## Connect to the database...

my $schema = HTGT::DBFactory->connect( 'eucomm_vector' );

my $sql = qq[
    select
      distinct
      p.project_id,
      p.is_eucomm EUCOMM, 
      p.is_komp_csd KOMP,
      p.is_mgp MGP,
      p.is_norcomm NORCOMM,
      g.mgi_accession_id MGI,
      p.design_plate_name || p.design_well_name DESIGN,
      p.design_id,
      p.design_instance_id,
      ws.pcs_plate_name PCS_PLATE,
      ws.pcs_well_name PCS_WELL,
      pc_clone.data_value PC_CLONE,
      ws.pc_pass_level PCS_QC_RESULT,
      ws.pc_qctest_result_id PCS_QC_RESULT_ID,
      ws.pcs_distribute PCS_DISTRIBUTE,
      pcs_com.data_value PCS_COMMENTS,
      ws.pgdgr_plate_name PGS_PLATE,
      ws.pgdgr_well_name PGS_WELL,
      ws.pgdgr_well_id PGS_WELL_ID,
      p.cassette,
      p.backbone,
      pg_clone.data_value PG_CLONE,
      ws.pg_pass_level PGS_QC_RESULT,
      ws.pg_qctest_result_id PGS_QC_RESULT_ID,
      ws.pgdgr_distribute PGS_DISTRIBUTE,
      pgs_com.data_value PGS_COMMENTS,
      g.marker_symbol,
      g.ensembl_gene_id,
      g.vega_gene_id,
      p.vector_only,
      p.esc_only
    from
      well_summary_by_di ws
      join project p on p.project_id = ws.project_id
      join mgi_gene g on g.mgi_gene_id = p.mgi_gene_id
      left join well_data pc_clone on pc_clone.well_id = ws.pcs_well_id and pc_clone.data_type = 'clone_name'
      left join well_data pg_clone on pg_clone.well_id = ws.pgdgr_well_id and pg_clone.data_type = 'clone_name'
      left join well_data pcs_com on pcs_com.well_id = ws.pcs_well_id and pcs_com.data_type = 'COMMENTS'
      left join well_data pgs_com on pgs_com.well_id = ws.pgdgr_well_id and pgs_com.data_type = 'COMMENTS'
      -- where esc_only = 1
    where p.is_publicly_reported = 1
    order by ws.pgdgr_plate_name, ws.pgdgr_well_name
];
  
my $dbh = $schema->storage->dbh;
my $sth = $dbh->prepare($sql);
$sth->execute();
print uc("project_id,EUCOMM,KOMP,MGP,NORCOMM,MGI,design,design_id,design_instance_id,PCS_PLATE,PCS_WELL,PC_CLONE,PCS_QC_RESULT,PCS_QC_RESULT_ID,PCS_DISTRIBUTE,PCS_COMMENTS,PGS_PLATE,PGS_WELL,PGS_WELL_ID,cassette,backbone,PG_CLONE,PGS_QC_RESULT,PGS_QC_RESULT_ID,PGS_DISTRIBUTE,PGS_COMMENTS,marker_symbol,ensembl_gene_id,vega_gene_id\n");
my $count = 0;
while(my @row = $sth->fetchrow_array){
    map {$_ =~ s/EP\n//} @row;
    map {$_ =~ s/\n//} @row;
    map {$_ =~ s/\cM\s*\n//} @row;
    my $esc_only = pop (@row);
    my $vector_only = pop (@row);
    my $is_eucomm = $row[1];
    my $is_komp_csd = $row[2];
    if($esc_only){
       if($is_eucomm){
         $row[1] = undef;
         $row[2] = 1;
       }
    }
    print join(',', map {qq["$_"]} @row)."\n";
    $count++;
    if(($count % 1000)==0){
        print STDERR "$count\n";
    }
}
