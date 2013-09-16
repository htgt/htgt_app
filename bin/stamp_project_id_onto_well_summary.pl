#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Data::Dumper;
use HTGT::DBFactory;

GetOptions(
    'debug|d'              => \my $debug,
    'verbose|v'            => \my $verbose,
    'help|?'               => \my $help,
    'well_summary=s'       => \my $well_summary,
    'well_summary_by_di=s' => \my $well_summary_by_di,
);

if ( $help || ( defined $ARGV[0] && $ARGV[0] =~ /\?|help/ ) ) {
    show_help();
    exit;
}

die "well_summary table name not specified" unless defined $well_summary;
die "well_summary_by_di table name not specified" unless defined $well_summary_by_di;

## Connect to the database...

my $schema = HTGT::DBFactory->connect( 'eucomm_vector' );

my $project_sql1 = qq[
    select project_id, design_instance_id, cassette, backbone
    from project
    where
    design_instance_id is not null
    and (esc_only != 1 or esc_only is null)
];

my $project_sql2 = qq[
    select project_id, design_instance_id, cassette, backbone
    from project
    where
    design_instance_id is not null
    and esc_only = 1
];

my $project_ws_update1 = qq [ update ${well_summary} set project_id = ? where design_instance_id = ? and cassette = ? and backbone = ? ];
my $project_ws_update2 = qq [ update ${well_summary} set project_id = ? where design_instance_id = ? and cassette is null and backbone is null ];
my $update_ws_sth1 = $schema->storage->dbh->prepare($project_ws_update1);
my $update_ws_sth2 = $schema->storage->dbh->prepare($project_ws_update2);

my $project_wsdi_update1 = qq [ update ${well_summary_by_di} set project_id = ? where design_instance_id = ? and cassette = ? and backbone = ? ];
my $project_wsdi_update2 = qq [ update ${well_summary_by_di} set project_id = ? where design_instance_id = ? and cassette is null and backbone is null ];
my $update_wsdi_sth1 = $schema->storage->dbh->prepare($project_wsdi_update1);
my $update_wsdi_sth2 = $schema->storage->dbh->prepare($project_wsdi_update2);


if($verbose){ print "${project_sql1}\n"; }
if($verbose){ print "${project_sql2}\n"; }

my $sth1 = $schema->storage->dbh->prepare($project_sql1);
my $sth2 = $schema->storage->dbh->prepare($project_sql2);

$sth1->execute();
$sth2->execute();

my $count = 0;
$schema->txn_do (
    sub {
        stamp_projects_onto_well_summary($sth1);
        stamp_projects_onto_well_summary($sth2);
    }
);


sub stamp_projects_onto_well_summary {
    my $sth = shift;
    while ( my @result = $sth->fetchrow_array() ){
            
        $count++;
        if(($count % 100) == 0){
            print "$count\n";
        }
        my ($project_id, $design_instance_id, $cassette, $backbone) = @result;
        
        if ($cassette) {
            $update_ws_sth1->execute($project_id, $design_instance_id, $cassette, $backbone);
            $update_wsdi_sth1->execute($project_id, $design_instance_id, $cassette, $backbone);
            
            # Fallback for entries without cassette/backbone
            $update_ws_sth2->execute($project_id, $design_instance_id);
            $update_wsdi_sth2->execute($project_id, $design_instance_id);
            
            if ($debug) {
                print ">$design_instance_id: $cassette : $backbone : $project_id\n";
            }
        } else {
            $update_ws_sth2->execute($project_id, $design_instance_id);
            $update_wsdi_sth2->execute($project_id, $design_instance_id);
            if ($debug) {
                print ">>$design_instance_id: $cassette : $backbone : $project_id\n";
            }
        }
            
    }
    
}
