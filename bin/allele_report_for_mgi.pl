#!/usr/bin/env perl

# script for generating mutant alleles report for mgi request
# Author: wy1@sanger.ac.uk

use warnings;
use strict;

use HTGT::DBFactory;
use IO::Handle;
use Text::CSV_XS;
use Readonly;

Readonly my @COLUMNS => qw(
    mgi_accession_id genome_build cassette project project_id
    cell_line_id cell_line_name allele_name mutation_type
    cassette_insertion loxp_insertion
);

Readonly my @HEADER => map { my $h = $_; $h =~ tr/_/ /; uc $h } @COLUMNS;

my $htgt  = HTGT::DBFactory->connect( 'eucomm_vector' );

my $ sql = qq [
   select   mgi_gene.MGI_ACCESSION_ID,
            project.is_eucomm,
            project.is_eucomm_tools,
            project.is_komp_csd,
            project.is_norcomm,
            project.project_id,
            project.cassette,
            w.allele_name,
            w.EPD_DISTRIBUTE,
            w.TARGETED_TRAP,
            w.ES_CELL_LINE,
            w.EPD_WELL_NAME,
            design.design_type,
            design.design_id,
            display_feature.feature_start, display_feature.feature_end,   
            feature.feature_type_id, display_feature.feature_strand strand
        from
            project,
            mgi_gene,
            well_summary_by_di w,
            design,
            design_instance, feature, display_feature
        where
            project.mgi_gene_id = mgi_gene.mgi_gene_id
            and project.project_id = w.project_id
            and (w.EPD_DISTRIBUTE = 'yes' or w.targeted_trap='yes')
            and w.design_instance_id = design_instance.design_instance_id
            and design.design_id = design_instance.design_id
            and design.design_id =  feature.design_id
            and feature.feature_id = display_feature.feature_id
            and feature.feature_type_id in (9,10,11,12)
            and display_feature.ASSEMBLY_ID = 11
            and project.is_publicly_reported = 1
        ];
        
$sql = $htgt->storage()->dbh()->prepare( $sql );

$sql->execute();

my $csv = Text::CSV_XS->new( { eol => "\n" } );
my $ofh = IO::Handle->new();
$ofh->fdopen( fileno(STDOUT), 'w' ) or die "dup STDOUT: $!";

$csv->print( $ofh, \@HEADER );

my %allele = ();

while( my $row = $sql->fetchrow_hashref() ) {
   # process the results   
      if(not exists $allele{$row->{EPD_WELL_NAME}}){
          
           $allele{$row->{EPD_WELL_NAME}}->{mgi_accession_id} = $row->{MGI_ACCESSION_ID};
           $allele{$row->{EPD_WELL_NAME}}->{genome_build} = "NCBIM37";
           $allele{$row->{EPD_WELL_NAME}}->{cassette} = $row->{CASSETTE};
           
           if (defined $row->{IS_EUCOMM} && $row->{IS_EUCOMM} == 1){
              $allele{$row->{EPD_WELL_NAME}}->{project} = "EUCOMM";
           }elsif(defined $row->{IS_EUCOMM_TOOLS} && $row->{IS_EUCOMM_TOOLS} == 1){
              $allele{$row->{EPD_WELL_NAME}}->{project} = "EUCOMM";
           }elsif(defined $row->{IS_KOMP_CSD} && $row->{IS_KOMP_CSD} == 1){
              $allele{$row->{EPD_WELL_NAME}}->{project} = "KOMP";
           }elsif(defined $row->{IS_NORCOMM} && $row->{IS_NORCOMM} ==1){
              $allele{$row->{EPD_WELL_NAME}}->{project} = "NORCOMM";
           }
           
           $allele{$row->{EPD_WELL_NAME}}->{project_id} = $row->{PROJECT_ID};
           $allele{$row->{EPD_WELL_NAME}}->{cell_line_id} = $row->{EPD_WELL_NAME};
           $allele{$row->{EPD_WELL_NAME}}->{allele_name} = $row->{ALLELE_NAME};
           $allele{$row->{EPD_WELL_NAME}}->{cell_line_name} = $row->{ES_CELL_LINE};
           
           if( (defined $row->{DESIGN_TYPE} && $row->{DESIGN_TYPE} eq 'KO') || (not defined $row->{DESIGN_TYPE})){
              if(defined $row->{TARGETED_TRAP} && $row->{TARGETED_TRAP} eq 'yes'){
                 $allele{$row->{EPD_WELL_NAME}}->{mutation_type} = "Targeted non-conditional";
              }elsif(defined $row->{EPD_DISTRIBUTE} && $row->{EPD_DISTRIBUTE} eq 'yes') {
                $allele{$row->{EPD_WELL_NAME}}->{mutation_type} = "Conditional";
              }
           }elsif(defined $row->{DESIGN_TYPE} && $row->{DESIGN_TYPE} =~ /Del/ ){
              $allele{$row->{EPD_WELL_NAME}}->{mutation_type} = "Deletion";
           }elsif(defined $row->{DESIGN_TYPE} && $row->{DESIGN_TYPE} =~ /Ins/ ){
              $allele{$row->{EPD_WELL_NAME}}->{mutation_type} = "Insertion";
           }
        
           $allele{$row->{EPD_WELL_NAME}}->{strand} = $row->{STRAND};
       }
      
       if($row->{FEATURE_TYPE_ID} == 9){
           $allele{$row->{EPD_WELL_NAME}}->{U5_start} = $row->{FEATURE_START};
           $allele{$row->{EPD_WELL_NAME}}->{U5_end} = $row->{FEATURE_END};
       }elsif($row->{FEATURE_TYPE_ID} == 10){
           $allele{$row->{EPD_WELL_NAME}}->{U3_start} = $row->{FEATURE_START};
           $allele{$row->{EPD_WELL_NAME}}->{U3_end} = $row->{FEATURE_END};
       }elsif($row->{FEATURE_TYPE_ID} == 11){
           $allele{$row->{EPD_WELL_NAME}}->{D5_start} = $row->{FEATURE_START};
           $allele{$row->{EPD_WELL_NAME}}->{D5_end} = $row->{FEATURE_END};
       }elsif($row->{FEATURE_TYPE_ID} == 12){
           $allele{$row->{EPD_WELL_NAME}}->{D3_start} = $row->{FEATURE_START};
           $allele{$row->{EPD_WELL_NAME}}->{D3_end} = $row->{FEATURE_END};
       }
}    

foreach my $href (values %{allele}){
    # work out the cassette & loxp insertion point
    if ($href->{strand} == 1){
        if ( $href->{mutation_type} eq "Conditional"){
            $href->{cassette_insertion} = $href->{U5_end}.'-'.$href->{U3_start};
            $href->{loxp_insertion} = $href->{D5_end}.'-'.$href->{D3_start};
        }elsif( $href->{mutation_type} eq "Targeted non-conditional"){
            $href->{cassette_insertion} = $href->{U5_end}.'-'.$href->{U3_start};
        }elsif( $href->{mutation_type} eq "Deletion" ||  $href->{mutation_type} eq "Insertion" ){
            $href->{cassette_insertion} =$href->{U5_end}.'-'.$href->{D3_start};
        }
    }else {
        if ( $href->{mutation_type} eq "Conditional"){
            $href->{cassette_insertion} = $href->{U3_end}.'-'.$href->{U5_start};
            $href->{loxp_insertion} = $href->{D3_end}.'-'.$href->{D5_start};
        }elsif( $href->{mutation_type} eq "Targeted non-conditional"){
            $href->{cassette_insertion} = $href->{U3_end}.'-'.$href->{U5_start};
         }elsif( $href->{mutation_type} eq "Deletion" ||  $href->{mutation_type} eq "Insertion" ){
            $href->{cassette_insertion} =$href->{D3_end}.'-'.$href->{U5_start};
        }
    }
    
    $csv->print( $ofh, [ map { defined $_ ? $_ : '-' } @{ $href }{ @COLUMNS } ] );
}
