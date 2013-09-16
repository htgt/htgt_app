#!/usr/bin/env perl
# $Id: fill_well_summary.pl 4589 2011-03-30 09:51:00Z rm7 $

use strict;
use warnings;

use DBI;
use Getopt::Long;
use Data::Dumper;
use HTGT::DBFactory;

GetOptions(
	"drop!"	         => \my $drop,
	"updatedb!"      => \my $updatedb,
	"debug!"         => \my $debug,
	"well_summary=s" => \my $well_summary,
) or die;
die "well_summary table name not specified" unless defined $well_summary;

my @col = qw(DESIGN_INSTANCE_ID DESIGN_PLATE_NAME DESIGN_WELL_NAME DESIGN_WELL_ID DESIGN_DESIGN_INSTANCE_ID BAC PCS_PLATE_NAME PCS_WELL_NAME PCS_WELL_ID PCS_DESIGN_INSTANCE_ID PC_QCTEST_RESULT_ID PC_PASS_LEVEL PCS_DISTRIBUTE PGDGR_PLATE_NAME PGDGR_WELL_NAME PGDGR_WELL_ID PGDGR_DESIGN_INSTANCE_ID PG_QCTEST_RESULT_ID PG_PASS_LEVEL cassette backbone PGDGR_DISTRIBUTE EP_PLATE_NAME EP_WELL_NAME EP_WELL_ID EP_DESIGN_INSTANCE_ID ES_CELL_LINE COLONIES_PICKED TOTAL_COLONIES EPD_PLATE_NAME EPD_WELL_NAME EPD_WELL_ID EPD_DESIGN_INSTANCE_ID EPD_QCTEST_RESULT_ID EPD_PASS_LEVEL EPD_DISTRIBUTE ALLELE_NAME TARGETED_TRAP);

my $sqlcreatetable = <<"SQLCT_EOT";
 CREATE TABLE "EUCOMM_VECTOR"."${well_summary}"
   (    "PROJECT_ID" NUMBER(*,0),
        "BUILD_GENE_ID" NUMBER(*,0),
        "GENE_ID" NUMBER(*,0),
        "DESIGN_INSTANCE_ID" NUMBER,
        "DESIGN_PLATE_NAME" VARCHAR2(100 BYTE),
        "DESIGN_WELL_NAME" VARCHAR2(24 BYTE),
        "DESIGN_WELL_ID" NUMBER,
        "DESIGN_DESIGN_INSTANCE_ID" NUMBER,
        "BAC" VARCHAR2(100 BYTE),
        "PCS_PLATE_NAME" VARCHAR2(100 BYTE),
        "PCS_WELL_NAME" VARCHAR2(24 BYTE),
        "PCS_WELL_ID" NUMBER,
        "PCS_DESIGN_INSTANCE_ID" NUMBER,
        "PC_QCTEST_RESULT_ID" NUMBER,
        "PC_PASS_LEVEL" VARCHAR2(100 BYTE),
        "PCS_DISTRIBUTE" VARCHAR2(100 BYTE),
        "PGDGR_PLATE_NAME" VARCHAR2(100 BYTE),
        "PGDGR_WELL_NAME" VARCHAR2(24 BYTE),
        "PGDGR_WELL_ID" NUMBER,
        "PGDGR_DESIGN_INSTANCE_ID" NUMBER,
        "PG_QCTEST_RESULT_ID" NUMBER,
        "PG_PASS_LEVEL" VARCHAR2(100 BYTE),
        "CASSETTE" VARCHAR2(100 BYTE),
        "BACKBONE" VARCHAR2(100 BYTE),
        "PGDGR_DISTRIBUTE" VARCHAR2(100 BYTE),
        "EP_PLATE_NAME" VARCHAR2(100 BYTE),
        "EP_WELL_NAME" VARCHAR2(24 BYTE),
        "EP_WELL_ID" NUMBER,
        "EP_DESIGN_INSTANCE_ID" NUMBER,
        "ES_CELL_LINE" VARCHAR2(100 BYTE),
        "COLONIES_PICKED" VARCHAR2(100 BYTE),
        "TOTAL_COLONIES" VARCHAR2(100 BYTE),
        "EPD_PLATE_NAME" VARCHAR2(100 BYTE),
        "EPD_WELL_NAME" VARCHAR2(24 BYTE),
        "EPD_WELL_ID" NUMBER(10,0),
        "EPD_DESIGN_INSTANCE_ID" NUMBER(10,0),
        "EPD_QCTEST_RESULT_ID" NUMBER(38,0),
        "EPD_PASS_LEVEL" VARCHAR2(100 BYTE),
        "EPD_DISTRIBUTE" VARCHAR2(100 BYTE),
        "ALLELE_NAME" VARCHAR2(160 BYTE),
        "TARGETED_TRAP" VARCHAR2(160 BYTE)
   ) TABLESPACE "DATA_01"
SQLCT_EOT

my $create_statement = {
  table  => $sqlcreatetable,
  index1 => qq{CREATE INDEX "EUCOMM_VECTOR"."${well_summary}_INDEX1" ON "EUCOMM_VECTOR"."${well_summary}" ("DESIGN_INSTANCE_ID", "CASSETTE", "BACKBONE") TABLESPACE "INDEX_01"},
  index2 => qq{CREATE INDEX "EUCOMM_VECTOR"."${well_summary}_INDEX2" ON "EUCOMM_VECTOR"."${well_summary}" ("DESIGN_INSTANCE_ID") TABLESPACE "INDEX_01"},
  index3 => qq{CREATE INDEX "EUCOMM_VECTOR"."${well_summary}_INDEX3" ON "EUCOMM_VECTOR"."${well_summary}" ("PROJECT_ID") TABLESPACE "INDEX_01"},
  grant1 => qq{grant select on ${well_summary} to euvect_ro_role},
  grant2 => qq{grant select on ${well_summary} to euvect_rw_role},
};

#pull back tree structure of well relations - one well per result
my $sqlq = <<SQLQ_EOT;
SELECT 
 PW.* ,PD1.DATA_VALUE BACS, WD1.DATA_VALUE cassette, WD2.DATA_VALUE backbone, 
 WD3.DATA_VALUE distribute, WD4.DATA_VALUE pass_level, WD5.DATA_VALUE qctest_result_id,
 PD2.DATA_VALUE ES_CELL_LINE, WD6.DATA_VALUE COLONIES_PICKED, WD7.DATA_VALUE TOTAL_COLONIES,
 WD8.DATA_VALUE ALLELE_NAME, WD9.DATA_VALUE targeted_trap, DI.DESIGN_INSTANCE_ID DI_DESIGN_INSTANCE_ID
FROM (
 SELECT ROWNUM CONNECT_INDEX, --connect_by_root well_id root_well_id, 
 CONNECT_BY_ISLEAF IS_LEAF, LEVEL LEV, p.name, p.type, w.* 
 from well w join plate p on w.plate_id=p.plate_id 
 connect by prior well_id=parent_well_id
 start with parent_well_id is null  -- not meant to work in conjunction with by root?
) PW
LEFT JOIN PLATE_DATA PD1 ON PD1.PLATE_ID=PW.PLATE_ID AND PD1.DATA_TYPE='bacs'
LEFT JOIN PLATE_DATA PD2 ON PD2.PLATE_ID=PW.PLATE_ID AND PD2.DATA_TYPE='es_cell_line'
LEFT JOIN WELL_DATA WD1 ON WD1.WELL_ID=PW.WELL_ID AND WD1.DATA_TYPE='cassette'
LEFT JOIN WELL_DATA WD2 ON WD2.WELL_ID=PW.WELL_ID AND WD2.DATA_TYPE='backbone'
LEFT JOIN WELL_DATA WD3 ON WD3.WELL_ID=PW.WELL_ID AND WD3.DATA_TYPE='distribute'
LEFT JOIN WELL_DATA WD4 ON WD4.WELL_ID=PW.WELL_ID AND WD4.DATA_TYPE='pass_level'
LEFT JOIN WELL_DATA WD5 ON WD5.WELL_ID=PW.WELL_ID AND WD5.DATA_TYPE='qctest_result_id'
LEFT JOIN WELL_DATA WD6 ON WD6.WELL_ID=PW.WELL_ID AND WD6.DATA_TYPE='COLONIES_PICKED'
LEFT JOIN WELL_DATA WD7 ON WD7.WELL_ID=PW.WELL_ID AND WD7.DATA_TYPE='TOTAL_COLONIES'
LEFT JOIN WELL_DATA WD8 ON WD8.WELL_ID=PW.WELL_ID AND WD8.DATA_TYPE='allele_name'
LEFT JOIN WELL_DATA WD9 ON WD9.WELL_ID=PW.WELL_ID AND WD9.DATA_TYPE='targeted_trap'
LEFT JOIN DESIGN_INSTANCE DI ON PW.NAME=DI.PLATE AND PW.WELL_NAME=DI.WELL AND TYPE='DESIGN'
ORDER BY CONNECT_INDEX --needed as otherwise order from subselect is lost - required for row building loop below
SQLQ_EOT

#print "$sqlq\n"; exit(0);


die "Need update if drop specified\n" if $drop and not $updatedb;

my $dbh = HTGT::DBFactory->dbi_connect( 'eucomm_vector' );

my $sth= $dbh->prepare($sqlq);
$sth->execute;
my @r;
my @stack;
my $rc=0;
my $wc=0;
my $ci=-1;
my $ws_well_ids=""; # well_ids for design, PCS, PGD, EP, EPD of last ws row created
my %ws_well_ids_done;

if($drop){
  my $drop_statement = {
    index1 => qq{DROP INDEX ${well_summary}_INDEX1},
    index2 => qq{DROP INDEX ${well_summary}_INDEX2},
    index3 => qq{DROP INDEX ${well_summary}_INDEX3},
    table  => qq{DROP TABLE ${well_summary}}
  };
  eval{
    my $drop_index1_sth = $dbh->prepare( $drop_statement->{index1} ); $drop_index1_sth->execute();
    my $drop_index2_sth = $dbh->prepare( $drop_statement->{index2} ); $drop_index2_sth->execute();
    my $drop_index3_sth = $dbh->prepare( $drop_statement->{index3} ); $drop_index3_sth->execute();
    my $drop_table_sth  = $dbh->prepare( $drop_statement->{table}  ); $drop_table_sth->execute();
  };
  warn $@ if $@;
  warn "Dropped ${well_summary}\n" if $debug;
  
  my $create_table_sth  = $dbh->prepare( $create_statement->{table}  ); $create_table_sth->execute();
  my $create_grant1_sth = $dbh->prepare( $create_statement->{grant1} ); $create_grant1_sth->execute();
  my $create_grant2_sth = $dbh->prepare( $create_statement->{grant2} ); $create_grant2_sth->execute();
  my $create_index1_sth = $dbh->prepare( $create_statement->{index1} ); $create_index1_sth->execute();
  my $create_index2_sth = $dbh->prepare( $create_statement->{index2} ); $create_index2_sth->execute();
  my $create_index3_sth = $dbh->prepare( $create_statement->{index3} ); $create_index3_sth->execute();
  
  warn "Created ${well_summary}\n" if $debug;
}else{
  my $d = $dbh->prepare(qq(DELETE FROM ${well_summary}));
  $d->execute;
  warn "Deleted from ${well_summary}\n" if $debug;
}

my $i = $dbh->prepare(qq{INSERT INTO ${well_summary} (} . join(",",@col) . ') VALUES (' . join(",",('?')x @col) . ')' );

while(my $rh = $sth->fetchrow_hashref){
  die "No type for well's plate! ".Dumper[$rh] unless $rh->{TYPE};
  $rc++; #row count
  if ($rh->{DESIGN_INSTANCE_ID} and $rh->{DI_DESIGN_INSTANCE_ID} 
      and $rh->{DESIGN_INSTANCE_ID}!=$rh->{DI_DESIGN_INSTANCE_ID}){
    warn "Internal design instance inconsistency for well ".$rh->{WELL_NAME}.", id ".$rh->{WELL_ID}.", on plate ".$rh->{NAME}."\n";
    next; # if there is anything downstream of these then we'll get as stack size inconsistency tomorrow
  }
  if ($rh->{CONNECT_INDEX} == $ci){
    warn "Excess plate or well data for well ".$rh->{WELL_NAME}.", id ".$rh->{WELL_ID}.", on plate ".$rh->{NAME}."\n";
    next; 
  }
  $ci = $rh->{CONNECT_INDEX};
  $wc++; #well count
  $#stack=$rh->{LEV}-2;#truncate stack back to below current level
  push @stack, $rh; #copyversion: {%$rh};
  die "Stack size inconsistency" unless $rh->{LEV}==scalar(@stack);
  #warn join ", ", $rh->{LEV}, scalar(@stack), $rh->{IS_LEAF};
  if ($rh->{IS_LEAF}){
    if ( grep $_->{NAME} =~ /^MOH/o, @stack ) {
      warn "Skipping MOH row: " . join( q{, }, map $_->{NAME}, @stack ) . "\n";
      next;            
    }      
    my ($design_w,$pcs_w,$pgdgr_w,$ep_w,$epd_w) = (
      (grep{$_->{TYPE} eq 'DESIGN'}@stack)[-1]|| {},
      (grep{$_->{TYPE} eq 'PCS'}@stack)[-1]|| {},
      (grep{{map{$_=>1}'PGD','PGR','GR','GRD'}->{$_->{TYPE}} }@stack)[-1]|| {},
      (grep{$_->{TYPE} eq 'EP'}@stack)[-1]|| {},
      (grep{$_->{TYPE} eq 'EPD'}@stack)[-1]|| {},
    );
    #print join(", ", map{$_->{WELL_ID}||""}$design_w,$pcs_w,$pgdgr_w,$ep_w,$epd_w)."\n";
    #warn join ", ", map{$_->{TYPE}||""}$design_w,$pcs_w,$pgdgr_w,$ep_w,$epd_w;
    my $new_ws_well_ids = join ", ", map{$_->{WELL_ID}||""}$design_w,$pcs_w,$pgdgr_w,$ep_w,$epd_w;
    #unless($ws_well_ids eq $new_ws_well_ids or $new_ws_well_ids eq ", , , , "){
    unless ( $ws_well_ids_done{$new_ws_well_ids}++ or ($new_ws_well_ids eq ", , , , ") ) {
	$ws_well_ids = $new_ws_well_ids;
	$i->execute(
            $design_w->{DI_DESIGN_INSTANCE_ID}||$design_w->{DESIGN_INSTANCE_ID}||$pcs_w->{DESIGN_INSTANCE_ID}||$pgdgr_w->{DESIGN_INSTANCE_ID}||$ep_w->{DESIGN_INSTANCE_ID}||$epd_w->{DESIGN_INSTANCE_ID}, #DESIGN_INSTANCE_ID
            $design_w->{NAME},               #DESIGN_PLATE_NAME 
            $design_w->{WELL_NAME},          #DESIGN_WELL_NAME 
            $design_w->{WELL_ID},            #DESIGN_WELL_ID 
            $design_w->{DESIGN_INSTANCE_ID}, #DESIGN_DESIGN_INSTANCE_ID 
            $design_w->{BACS},                #BAC 
            $pcs_w->{NAME},               #PCS_PLATE_NAME 
            $pcs_w->{WELL_NAME},          #PCS_WELL_NAME 
            $pcs_w->{WELL_ID},            #PCS_WELL_ID 
            $pcs_w->{DESIGN_INSTANCE_ID}, #PCS_DESIGN_INSTANCE_ID 
            $pcs_w->{QCTEST_RESULT_ID},   #PC_QCTEST_RESULT_ID 
            $pcs_w->{PASS_LEVEL},         #PC_PASS_LEVEL 
            $pcs_w->{DISTRIBUTE},         #PCS_DISTRIBUTE 
            $pgdgr_w->{NAME},               #PGDGR_PLATE_NAME 
            $pgdgr_w->{WELL_NAME},          #PGDGR_WELL_NAME 
            $pgdgr_w->{WELL_ID},            #PGDGR_WELL_ID 
            $pgdgr_w->{DESIGN_INSTANCE_ID}, #PGDGR_DESIGN_INSTANCE_ID 
            $pgdgr_w->{QCTEST_RESULT_ID},   #PG_QCTEST_RESULT_ID 
            $pgdgr_w->{PASS_LEVEL},         #PG_PASS_LEVEL 
            $pgdgr_w->{CASSETTE}||$ep_w->{CASSETTE}||$epd_w->{CASSETTE},           #cassette 
            $pgdgr_w->{BACKBONE}||$ep_w->{BACKBONE}||$epd_w->{BACKBONE},           #backbone 
            $pgdgr_w->{DISTRIBUTE},         #PGDGR_DISTRIBUTE 
            $ep_w->{NAME}, #EP_PLATE_NAME 
            $ep_w->{WELL_NAME}, #EP_WELL_NAME 
            $ep_w->{WELL_ID}, #EP_WELL_ID 
            $ep_w->{DESIGN_INSTANCE_ID}, #EP_DESIGN_INSTANCE_ID 
            $ep_w->{ES_CELL_LINE}, #ES_CELL_LINE 
            $ep_w->{COLONIES_PICKED}, #COLONIES_PICKED 
            $ep_w->{TOTAL_COLONIES}, #TOTAL_COLONIES 
            $epd_w->{NAME}, #EPD_PLATE_NAME 
            $epd_w->{WELL_NAME}, #EPD_WELL_NAME 
            $epd_w->{WELL_ID}, #EPD_WELL_ID 
            $epd_w->{DESIGN_INSTANCE_ID}, #EPD_DESIGN_INSTANCE_ID 
            $epd_w->{QCTEST_RESULT_ID}, #EPD_QCTEST_RESULT_ID 
            $epd_w->{PASS_LEVEL}, #EPD_PASS_LEVEL 
            $epd_w->{DISTRIBUTE}, #EPD_DISTRIBUTE
            $epd_w->{ALLELE_NAME}, #ALLELE_NAME,
            $epd_w->{TARGETED_TRAP}
      );
      #warn join ", ",map{defined $_ ? $_ : ""}@{$r[-1]} if ${$r[-1]}[7];
    }
  }
}
#warn Dumper [[@r[-3,-2,-1]]];
#warn "$rc query results trimmed to $wc wells, processed to get ".scalar(@rleaf)." pipelines, trimmed to ".scalar(@r)." d->pcs->pgdgr->ep->epd pipelines for insertion in ${well_summary}\n" if $debug;

#exit(0);

#Now fill in GENE_ID and BUILD_GENE_ID column
my $sql_g_bg =<<"SQL_G_BG_EOT";
 SELECT
  Q.design_instance_id,
  MIN(Q.gene_id) gene_id,
  decode(MIN(Q.gene_id),   NULL,   'none',   MAX(Q.gene_id),   'one',   'multiple') gene_match,
  MIN(Q.build_gene_id) build_gene_id,
  decode(MIN(Q.build_gene_id),   NULL,   'none',   MAX(Q.build_gene_id),   'one',   'multiple') build_gene_match
 FROM(
   SELECT DISTINCT design_instance.design_instance_id, g2g.gene_id, gbg.id build_gene_id
   FROM design_instance
   LEFT JOIN (design
     JOIN mig.gnm_exon e ON e.id = design.start_exon_id
     JOIN mig.gnm_transcript t ON t.id = e.transcript_id
     JOIN mig.gnm_gene_build_gene gbg ON t.build_gene_id = gbg.id
     JOIN mig.gnm_gene_2_gene_build_gene g2g ON g2g.gene_build_gene_id = gbg.id
   )ON design_instance.design_id = design.design_id
   WHERE design_instance_id IN (SELECT DISTINCT design_instance_id FROM ${well_summary})
 )Q
 GROUP BY design_instance_id
 ORDER BY design_instance_id
SQL_G_BG_EOT

my $sql_g_bg_u =<<"SQL_G_BG_U_EOT";
UPDATE ${well_summary} SET build_gene_id=?, gene_id=? WHERE design_instance_id = ?
SQL_G_BG_U_EOT

my $sth_g_bg = $dbh->prepare($sql_g_bg);
my $sth_g_bg_u = $dbh->prepare($sql_g_bg_u);
$sth_g_bg->execute();
my $di_c=0;
while(my $rh = $sth_g_bg->fetchrow_hashref){
  $di_c++;
  warn "design_instance_id: ".$rh->{DESIGN_INSTANCE_ID}.", gene_match: ".$rh->{GENE_MATCH}.", build_gene_match: ".$rh->{BUILD_GENE_MATCH}."\n"  if($rh->{GENE_MATCH} ne 'one' or $rh->{BUILD_GENE_MATCH} ne 'one' );
  $sth_g_bg_u->execute(@{$rh}{qw(BUILD_GENE_ID GENE_ID DESIGN_INSTANCE_ID)});
}
warn "Updated build_gene_id and gene_id info for $di_c design instances\n" if $debug;


if($updatedb){
  $dbh->commit();
  warn "Committed!\n" if $debug;
}else{
  $dbh->rollback();
  warn "Rolled back!\n";
}

$dbh->disconnect;




