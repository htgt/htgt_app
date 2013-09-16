#!/usr/bin/env perl
# $Id: fill_well_summary_by_di.pl 1865 2010-06-08 13:19:16Z rm7 $

use strict;
use warnings;

use HTGT::DBFactory;
use Getopt::Long;
use Data::Dumper;
use Log::Log4perl ':easy';

my $log_level = $WARN;

GetOptions(
    "drop!"                => \my $drop,
    "updatedb|commit"      => \my $updatedb,
    "debug"                => sub { $log_level = $DEBUG },
    "verbose"              => sub { $log_level = $INFO },
    "well_summary_by_di=s" => \my $well_summary_by_di,
) or die "Usage: $0 [OPTIONS]\n";

die "well_summary_by_di table name not specified"
    unless defined $well_summary_by_di;

Log::Log4perl->easy_init(
    {
        level  => $log_level,
        layout => '%p %m%n',
    }
);

INFO("beginning fill_well_summary_by_di for table name $well_summary_by_di");

my @col
    = qw(DESIGN_INSTANCE_ID DESIGN_PLATE_NAME DESIGN_WELL_NAME DESIGN_WELL_ID BAC PCS_PLATE_NAME PCS_WELL_NAME PCS_WELL_ID PC_QCTEST_RESULT_ID PC_PASS_LEVEL PCS_DISTRIBUTE PGDGR_PLATE_NAME PGDGR_WELL_NAME PGDGR_WELL_ID PG_QCTEST_RESULT_ID PG_PASS_LEVEL cassette backbone PGDGR_DISTRIBUTE EP_PLATE_NAME EP_WELL_NAME EP_WELL_ID ES_CELL_LINE COLONIES_PICKED TOTAL_COLONIES EPD_PLATE_NAME EPD_WELL_NAME EPD_WELL_ID EPD_QCTEST_RESULT_ID EPD_PASS_LEVEL EPD_DISTRIBUTE TARGETED_TRAP ALLELE_NAME);
my $sqlcreatetable = <<"SQLCT_EOT";
    CREATE TABLE "EUCOMM_VECTOR"."${well_summary_by_di}" (
        "PROJECT_ID" NUMBER(*,0),
        "BUILD_GENE_ID" NUMBER(*,0),
        "GENE_ID" NUMBER(*,0),
        "DESIGN_INSTANCE_ID" NUMBER,
        "DESIGN_PLATE_NAME" VARCHAR2(100 BYTE),
        "DESIGN_WELL_NAME" VARCHAR2(24 BYTE),
        "DESIGN_WELL_ID" NUMBER,
        "BAC" VARCHAR2(100 BYTE),
        "PCS_PLATE_NAME" VARCHAR2(100 BYTE),
        "PCS_WELL_NAME" VARCHAR2(24 BYTE),
        "PCS_WELL_ID" NUMBER,
        "PC_QCTEST_RESULT_ID" NUMBER,
        "PC_PASS_LEVEL" VARCHAR2(100 BYTE),
        "PCS_DISTRIBUTE" VARCHAR2(100 BYTE),
        "PGDGR_PLATE_NAME" VARCHAR2(100 BYTE),
        "PGDGR_WELL_NAME" VARCHAR2(24 BYTE),
        "PGDGR_WELL_ID" NUMBER,
        "PG_QCTEST_RESULT_ID" NUMBER,
        "PG_PASS_LEVEL" VARCHAR2(100 BYTE),
        "CASSETTE" VARCHAR2(100 BYTE),
        "BACKBONE" VARCHAR2(100 BYTE),
        "PGDGR_DISTRIBUTE" VARCHAR2(100 BYTE),
        "EP_PLATE_NAME" VARCHAR2(100 BYTE),
        "EP_WELL_NAME" VARCHAR2(24 BYTE),
        "EP_WELL_ID" NUMBER,
        "ES_CELL_LINE" VARCHAR2(100 BYTE),
        "COLONIES_PICKED" VARCHAR2(500 BYTE),
        "TOTAL_COLONIES" VARCHAR2(100 BYTE),
        "EPD_PLATE_NAME" VARCHAR2(100 BYTE),
        "EPD_WELL_NAME" VARCHAR2(24 BYTE),
        "EPD_WELL_ID" NUMBER(10,0),
        "EPD_QCTEST_RESULT_ID" NUMBER(38,0),
        "EPD_PASS_LEVEL" VARCHAR2(100 BYTE),
        "EPD_DISTRIBUTE" VARCHAR2(100 BYTE),
        "TARGETED_TRAP" VARCHAR2(100 BYTE),
        "ALLELE_NAME" VARCHAR2(160 BYTE)
    ) TABLESPACE "DATA_01"
SQLCT_EOT

my $create_statement = {
    table => $sqlcreatetable,
    index1 =>
        qq{CREATE INDEX "EUCOMM_VECTOR"."${well_summary_by_di}_INDEX1" ON "EUCOMM_VECTOR"."${well_summary_by_di}" ("DESIGN_INSTANCE_ID", "CASSETTE", "BACKBONE") TABLESPACE "INDEX_01"},
    index2 =>
        qq{CREATE INDEX "EUCOMM_VECTOR"."${well_summary_by_di}_INDEX2" ON "EUCOMM_VECTOR"."${well_summary_by_di}" ("DESIGN_INSTANCE_ID") TABLESPACE "INDEX_01"},
    index3 =>
        qq{CREATE INDEX "EUCOMM_VECTOR"."${well_summary_by_di}_INDEX3" ON "EUCOMM_VECTOR"."${well_summary_by_di}" ("PROJECT_ID") TABLESPACE "INDEX_01"},
    index4 =>
        qq{CREATE UNIQUE INDEX ${well_summary_by_di}_INDEX4 ON ${well_summary_by_di} (DESIGN_WELL_ID, PCS_WELL_ID, PGDGR_WELL_ID, EP_WELL_ID, EPD_WELL_ID) TABLESPACE "INDEX_01"},
    index5 =>
        qq{CREATE UNIQUE INDEX ${well_summary_by_di}_INDEX5 ON ${well_summary_by_di} (EPD_WELL_ID) TABLESPACE "INDEX_01"},
    grant1 => qq{grant select on ${well_summary_by_di} to euvect_ro_role},
    grant2 => qq{grant select on ${well_summary_by_di} to euvect_rw_role},
};

#pull back tree structure of well relations - one well per result
my $sqlq = <<SQLQ_EOT;
    SELECT 
        PW.* ,PD1.DATA_VALUE BACS, WD1.DATA_VALUE cassette, WD2.DATA_VALUE backbone, 
        WD3.DATA_VALUE distribute, WD4.DATA_VALUE pass_level, WD5.DATA_VALUE qctest_result_id,
        PD2.DATA_VALUE ES_CELL_LINE, WD6.DATA_VALUE COLONIES_PICKED, WD7.DATA_VALUE TOTAL_COLONIES,    
        WD8.DATA_VALUE ALLELE_NAME, WD9.DATA_VALUE targeted_trap, DI.DESIGN_INSTANCE_ID DI_DESIGN_INSTANCE_ID
    FROM (
        SELECT ROWNUM CONNECT_INDEX, 
        CONNECT_BY_ISLEAF IS_LEAF, LEVEL LEV, p.name, p.type, w.* 
        from well w join plate p on w.plate_id=p.plate_id 
        connect by prior well_id=parent_well_id AND prior design_instance_id=design_instance_id
        start with well_id in (
            select well.well_ID from well 
            left join well pw on well.parent_well_id=pw.well_id 
            where well.parent_well_id is null or well.design_instance_id != pw.design_instance_id
        )
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

die "Need update if drop specified\n" if $drop and not $updatedb;

my $s = HTGT::DBFactory->connect('eucomm_vector');
$s->txn_do(
    sub {

        DEBUG("fetching dbh");
        my $dbh = $s->storage->dbh;

        my $sth = $dbh->prepare($sqlq);
        $sth->execute;

        if ($drop) {
            my $drop_statement = {
                index1 => qq{DROP INDEX ${well_summary_by_di}_INDEX1},
                index2 => qq{DROP INDEX ${well_summary_by_di}_INDEX2},
                index3 => qq{DROP INDEX ${well_summary_by_di}_INDEX3},
                index4 => qq{DROP INDEX ${well_summary_by_di}_INDEX4},
                index5 => qq{DROP INDEX ${well_summary_by_di}_INDEX5},
                table  => qq{DROP TABLE ${well_summary_by_di}}
            };
            eval {
                my $drop_index1_sth = $dbh->prepare( $drop_statement->{index1} );
                $drop_index1_sth->execute();
                my $drop_index2_sth = $dbh->prepare( $drop_statement->{index2} );
                $drop_index2_sth->execute();
                my $drop_index3_sth = $dbh->prepare( $drop_statement->{index3} );
                $drop_index3_sth->execute();
                my $drop_index4_sth = $dbh->prepare( $drop_statement->{index4} );
                $drop_index4_sth->execute();
                my $drop_index5_sth = $dbh->prepare( $drop_statement->{index5} );
                $drop_index5_sth->execute();
                my $drop_table_sth = $dbh->prepare( $drop_statement->{table} );
                $drop_table_sth->execute();
            };
            ERROR($@) if $@;
            INFO("Dropped ${well_summary_by_di}");

            my $create_table_sth = $dbh->prepare( $create_statement->{table} );
            $create_table_sth->execute();
            my $create_grant1_sth = $dbh->prepare( $create_statement->{grant1} );
            $create_grant1_sth->execute();
            my $create_grant2_sth = $dbh->prepare( $create_statement->{grant2} );
            $create_grant2_sth->execute();
            my $create_index1_sth = $dbh->prepare( $create_statement->{index1} );
            $create_index1_sth->execute();
            my $create_index2_sth = $dbh->prepare( $create_statement->{index2} );
            $create_index2_sth->execute();
            my $create_index3_sth = $dbh->prepare( $create_statement->{index3} );
            $create_index3_sth->execute();
            my $create_index4_sth = $dbh->prepare( $create_statement->{index4} );
            $create_index4_sth->execute();
            my $create_index5_sth = $dbh->prepare( $create_statement->{index5} );
            $create_index5_sth->execute();

            INFO("Created ${well_summary_by_di}");
        }
        else {
            my $d = $dbh->prepare(qq(DELETE FROM ${well_summary_by_di}));
            $d->execute;
            INFO("All rows deleted from ${well_summary_by_di}");
        }

        # THIS IS FIRST TIME THAT @col IS USED - PERHAPS IT SHOULD ALSO BE DEFINED HERE - DAVE SUGGESTION.
        my $i
            = $dbh->prepare( qq{INSERT INTO ${well_summary_by_di} (}
                . join( ",", @col )
                . ') VALUES ('
                . join( ",", ('?') x @col )
                . ')' );

        my @r;
        my @stack;
        my $rc          = 0;
        my $ws_well_ids = "";    # well_ids for design, PCS, PGD, EP, EPD of last ws row created
        my %ws_well_ids_done;
        my $wc = 0;
        my $ci = -1;

        INFO("Start looping / insertion of rows ...");

        while ( my $rh = $sth->fetchrow_hashref ) {
            $rc++;               #row count
            die "No type for well's plate! " . Dumper [$rh]
                unless $rh->{TYPE};
            if (    $rh->{DESIGN_INSTANCE_ID}
                and $rh->{DI_DESIGN_INSTANCE_ID}
                and $rh->{DESIGN_INSTANCE_ID} != $rh->{DI_DESIGN_INSTANCE_ID} )
            {
                WARN(     "Internal design instance inconsistency for well "
                        . $rh->{WELL_NAME} . ", id "
                        . $rh->{WELL_ID}
                        . ", on plate "
                        . $rh->{NAME} );
                next;    # if there is anything downstream of these then we'll get as stack size inconsistency tomorrow
            }

            if ( $rh->{CONNECT_INDEX} == $ci ) {    #Well entry repeated due to well_data or plate_data joins
                WARN(     "Excess plate or well data for well "
                        . $rh->{WELL_NAME} . ", id "
                        . $rh->{WELL_ID}
                        . ", on plate "
                        . $rh->{NAME} );
                next;
            }

            $ci = $rh->{CONNECT_INDEX};
            $wc++;                                  #well count
            $#stack = $rh->{LEV} - 2;               #truncate stack back to below current level
            push @stack, $rh;                       #copyversion: {%$rh};
            die "Stack size inconsistency"
                unless $rh->{LEV} == scalar(@stack);

            #warn join ", ", $rh->{LEV}, scalar(@stack), $rh->{IS_LEAF};
            if ( $rh->{IS_LEAF} ) {

                if ( grep $_->{NAME} =~ /^MOH/o, @stack ) {
                    WARN( "Skipping MOH row: " . join( q{, }, map $_->{NAME}, @stack ) );
                    next;
                }

                my ( $design_w, $pcs_w, $pgdgr_w, $ep_w, $epd_w ) = (
                    ( grep { $_->{TYPE} eq 'DESIGN' } @stack )[-1] || {},
                    ( grep { $_->{TYPE} eq 'PCS' } @stack )[-1]    || {},
                    (   grep {
                            {
                                map { $_ => 1 } 'PGD', 'PGR', 'GR', 'GRD'
                            }
                            ->{ $_->{TYPE} }
                            } @stack
                        )[-1]
                        || {},
                    ( grep { $_->{TYPE} eq 'EP' } @stack )[-1]  || {},
                    ( grep { $_->{TYPE} eq 'EPD' } @stack )[-1] || {},
                );

                my $new_ws_well_ids = join ", ", map { $_->{WELL_ID} || "" } $design_w, $pcs_w, $pgdgr_w, $ep_w, $epd_w;
                unless ( $ws_well_ids_done{$new_ws_well_ids}++ or ( $new_ws_well_ids eq ", , , , " ) ) {
                    $ws_well_ids = $new_ws_well_ids;
                    $i->execute(
                               $design_w->{DI_DESIGN_INSTANCE_ID}
                            || $design_w->{DESIGN_INSTANCE_ID}
                            || $pcs_w->{DESIGN_INSTANCE_ID}
                            || $pgdgr_w->{DESIGN_INSTANCE_ID}
                            || $ep_w->{DESIGN_INSTANCE_ID}
                            || $epd_w->{DESIGN_INSTANCE_ID},    #DESIGN_INSTANCE_ID
                        $design_w->{NAME},                      #DESIGN_PLATE_NAME
                        $design_w->{WELL_NAME},                 #DESIGN_WELL_NAME
                        $design_w->{WELL_ID},                   #DESIGN_WELL_ID
                        $design_w->{BACS},                      #BAC
                        $pcs_w->{NAME},                         #PCS_PLATE_NAME
                        $pcs_w->{WELL_NAME},                    #PCS_WELL_NAME
                        $pcs_w->{WELL_ID},                      #PCS_WELL_ID
                        $pcs_w->{QCTEST_RESULT_ID},             #PC_QCTEST_RESULT_ID
                        $pcs_w->{PASS_LEVEL},                   #PC_PASS_LEVEL
                        $pcs_w->{DISTRIBUTE},                   #PCS_DISTRIBUTE
                        $pgdgr_w->{NAME},                       #PGDGR_PLATE_NAME
                        $pgdgr_w->{WELL_NAME},                  #PGDGR_WELL_NAME
                        $pgdgr_w->{WELL_ID},                    #PGDGR_WELL_ID
                        $pgdgr_w->{QCTEST_RESULT_ID},           #PG_QCTEST_RESULT_ID
                        $pgdgr_w->{PASS_LEVEL},                 #PG_PASS_LEVEL
                        $pgdgr_w->{CASSETTE}
                            || $ep_w->{CASSETTE}
                            || $epd_w->{CASSETTE},              #cassette
                        $pgdgr_w->{BACKBONE}
                            || $ep_w->{BACKBONE}
                            || $epd_w->{BACKBONE},              #backbone
                        $pgdgr_w->{DISTRIBUTE},                 #PGDGR_DISTRIBUTE
                        $ep_w->{NAME},                          #EP_PLATE_NAME
                        $ep_w->{WELL_NAME},                     #EP_WELL_NAME
                        $ep_w->{WELL_ID},                       #EP_WELL_ID
                        $ep_w->{ES_CELL_LINE},                  #ES_CELL_LINE
                        $ep_w->{COLONIES_PICKED},               #COLONIES_PICKED
                        $ep_w->{TOTAL_COLONIES},                #TOTAL_COLONIES
                        $epd_w->{NAME},                         #EPD_PLATE_NAME
                        $epd_w->{WELL_NAME},                    #EPD_WELL_NAME
                        $epd_w->{WELL_ID},                      #EPD_WELL_ID
                        $epd_w->{QCTEST_RESULT_ID},             #EPD_QCTEST_RESULT_ID
                        $epd_w->{PASS_LEVEL},                   #EPD_PASS_LEVEL
                        $epd_w->{DISTRIBUTE},                   #EPD_DISTRIBUTE

                        $epd_w->{TARGETED_TRAP},                #TARGETED_TRAP - added by Dan.
                        $epd_w->{ALLELE_NAME},                  #ALLELE_NAME
                    );
                }
            }
        }

        INFO("fetching null es_cell_lines");

        my $update_cell_line_sth = $dbh->prepare( <<"EOT" );
update ${well_summary_by_di} set es_cell_line = ? where epd_well_id = ?
EOT

        my ($missing_cell_line_count) = $dbh->selectrow_array( <<"EOT" );
select count(*) from ${well_summary_by_di}
where design_instance_id is not null
and epd_well_id is not null
and es_cell_line is null
EOT

        INFO("$missing_cell_line_count rows with EPD missing es_cell_line");

        my $missing_cell_lines_sth = $dbh->prepare( <<"EOT" );
select epd_well_id from ${well_summary_by_di}
where design_instance_id is not null
and epd_well_id is not null
and es_cell_line is null
EOT

        $missing_cell_lines_sth->execute;

        my $update_count = 0;

        while ( my ($epd_well_id) = $missing_cell_lines_sth->fetchrow_array ) {

            my $well = $s->resultset('HTGTDB::Well')->find( { well_id => $epd_well_id } );
            unless ($well) {
                ERROR("cant't find well for EPD well id $epd_well_id");
                next;
            }

            my $es_cell_line = $well->es_cell_line;
            unless ($es_cell_line) {
                ERROR("can't find es_cell_line for EPD well id $epd_well_id");
                next;
            }

            my $rv = $update_cell_line_sth->execute( $es_cell_line, $epd_well_id );
            if ($rv) {
                DEBUG("updated $rv EPD wells with id $epd_well_id to cell line $es_cell_line");
                $update_count += $rv;
            }
        }

        INFO("updated $update_count cell line names");

        unless ($updatedb) {
            WARN("Rollback");
            $s->txn_rollback();
        }
    }
);
