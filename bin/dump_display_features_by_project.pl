#!/usr/bin/env perl

use strict;
use Getopt::Long;
use Data::Dumper;
use HTGT::DBFactory;

my $debug;
my $verbose;
my $help;
my $test_data;
my $inject_into_test;

GetOptions(
    'debug|d'          => \$debug,
    'verbose|v'        => \$verbose,
    'help|?'           => \$help,
);

## Catch calls for help!

if ( $help || ( defined $ARGV[0] && $ARGV[0] =~ /\?|help/ ) ) {
    show_help();
    exit;
}

## Connect to the database...

my $designs_to_avoid = {};

my $schema = HTGT::DBFactory->connect( 'eucomm_vector' );

my $sql = qq[
    select 
    project.project_id,
    project.design_id,
    display_feature.display_feature_type, 
    chromosome_dict.name, 
    display_feature.feature_start, 
    display_feature.feature_end, 
    display_feature.feature_strand,
    project.is_eucomm,
    project.is_komp_csd,
    project.is_komp_regeneron,
    project.is_norcomm,
    project_status.name
    from 
    project, design, feature, display_feature, chromosome_dict, project_status
    where 
    project.design_id = design.design_id
    and feature.design_id = design.design_id
    and display_feature.feature_id = feature.feature_id
    and display_feature.display_feature_type in ('G5','G3','U5','U3','D5','D3')
    and display_feature.chr_id = chromosome_dict.chr_id
    and display_feature.assembly_id = 11
    and project_status.project_status_id = project.project_status_id
    and (is_eucomm =1 or is_komp_csd=1 or is_norcomm = 1)
    and project.is_publicly_reported = 1
    order by project_id, project.design_id, display_feature.feature_start
];

my $sth = $schema->storage->dbh->prepare($sql);
print STDERR "starting db execute\n";
$sth->execute();

print STDERR "starting print \n";
while ( my @result = $sth->fetchrow_array ) {
    my $project_id = $result[0];
    my $design_id = $result[1];

    next if ($designs_to_avoid->{$design_id});

    my $display_feature_type = $result[2];
    my $chr = $result[3];
    my $start = $result[4];
    my $end = $result[5];
    my $strand = $result[6];
    my $is_eucomm = $result[7];
    my $is_komp_csd = $result[8];
    my $is_komp_regeneron = $result[9];
    my $is_norcomm = $result[10];
    my $project_status = $result[11];
    my $label;
    if($is_eucomm){
        $label = "EUCOMM $project_status";
    }elsif($is_komp_csd){
        $label = "KOMP_CSD $project_status";
    }elsif($is_norcomm){
        $label = "NORCOMM $project_status";
    }else{
        next;
    }

    
    if($strand == 1){
        $strand = '+';
    }elsif($strand == -1){
        $strand = '-';
    }else{
        die "strand unrecognised: $strand\n";
    }
    
    print
        "${project_id}_${design_id}\tWTSI\t${display_feature_type}\t${chr}\t${start}\t${end}\t${strand}\t.\t".
        "design_id=${design_id};URL=http://www.sanger.ac.uk/htgt/report/gene_report?project_id=${project_id}".
        ";pipeline_status=$label\n";
    
}
