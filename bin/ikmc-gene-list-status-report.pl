#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/ikmc-gene-list-status-report.pl $
# $LastChangedRevision: 8068 $
# $LastChangedDate: 2013-02-08 07:13:44 +0000 (Fri, 08 Feb 2013) $
# $LastChangedBy: vvi $
#

use strict;

use Getopt::Long;
use Pod::Usage;
use HTGT::BioMart::QueryFactory;
use File::Temp;
use LWP::Simple ();
use Iterator;
use Const::Fast;
use DateTime;
use DateTime::Format::Builder;
use DateTime::Format::Flexible;
use Smart::Comments;

# const my $MGP_GENES => "mgp_gene_selection_round2.csv"; #not interesting, ignore
const my $MASTER_GENELIST_URL  => 'http://www.knockoutmouse.org/download/genelist';
const my $PHENO_ALLELE_URL => 'ftp://ftp.informatics.jax.org/pub/reports/MGI_PhenotypicAllele.rpt';
const my $MGI_GO_URL => 'ftp://ftp.informatics.jax.org/pub/reports/gene_association.mgi';
const my $UCD_FILE => "KOMP_Phenotype_Gene_List.csv";
# const my $PRIORITY => 'high_priority_genes_24_july_2011.csv';#  harder - I'll explain
# const my $EUCOMM_KOMP_PRIORITY_IN_HTGT => 'eucomm_or_komp_in_htgt.txt'; #  harder - I'll explain

const my $MARTSERVICE_URL      => 'http://www.knockoutmouse.org/biomart/martservice'; # used to get ES cell availability, mice in imits

const my @PIPELINES => ( 'EUCOMM', 'KOMP-CSD', 'KOMP-Regeneron', 'NorCOMM', 'Sanger MGP' );

const my @MUTATION_TYPES => ( 'Conditional Ready', 'Targeted Non Conditional', 'Deletion' );

my $annotated_mgp_genes = {};

sub DEBUG {}

{
 
    #$annotated_mgp_genes = get_annotated_mgp_genes(); ignore

    #1 needs to be a remote fetch
    my ($master_genelist,$marker_to_mgi) = get_master_genelist();
    my $qf = HTGT::BioMart::QueryFactory->new( $MARTSERVICE_URL );
    
    # this can be ignored.
    #my $ucd_injection_data = get_ucd_injection_data($marker_to_mgi);
    #foreach my $mgi_accession (keys %$ucd_injection_data){
    #    if($master_genelist->{$mgi_accession}){
    #        $master_genelist->{$mgi_accession}->{ucd} = $ucd_injection_data->{$mgi_accession};
    #    }
    #}
    
    # 2 mgi - based old mice - make a remote fetch
    my $existing_mice   = get_pheno_allele_data();
    foreach my $mgi_accession (keys %$existing_mice){
        if($master_genelist->{$mgi_accession}){
            $master_genelist->{$mgi_accession}->{pheno} = $existing_mice->{$mgi_accession};
        }
    }

    # already a remote (imits) fetch - test
    my $microinjections = get_microinjections( $qf );    
    foreach my $mgi_accession (keys %$microinjections){
        if($master_genelist->{$mgi_accession}){
            $master_genelist->{$mgi_accession}->{mice} = $microinjections->{$mgi_accession};
        }
    }
    
    # already a remote fetch
    my $products        = get_targ_rep_products( $qf );
    foreach my $mgi_accession (keys %$products){
        if($master_genelist->{$mgi_accession}){
            $master_genelist->{$mgi_accession}->{products} = $products->{$mgi_accession};
        }
    }
    
    # 3 make a remote fetch
    my $go_annotations = get_go_annotations();
    foreach my $mgi_accession (keys %$go_annotations){
        if($master_genelist->{$mgi_accession}){
            $master_genelist->{$mgi_accession}->{go_count} = $go_annotations->{$mgi_accession};
        }
    }
    
    # this can be ignored.
    #my @high_priority_genes = @{get_high_priority_genes()};
    #foreach my $mgi_accession (@high_priority_genes){
    #    if($master_genelist->{$mgi_accession}){
    #        $master_genelist->{$mgi_accession}->{high_priority} = 1;
    #    }
    #}

    print
      #  "MGPAnnotations,Comment,MGI ID,Symbol,Chr,".
      #  "Conditionals,Targeted trap,Deletion,".
      #  "UCD mice,UCD MI,".
      #  "IKMC Microinj,IKMC mice,Last MI date,IKMC centre(s),".
      #  "Other mice - targeted,Other mice - cond,Lethality (MP:0010768),pubs,GO count,".
      #  "CSD status,REGN status,EUCOMM status,NorCOMM status,".
      #  "CSD-cond,CSD-tt,CSD-del,EUCOMM-cond,EUCOMM-tt,mirKO-del,Reg-Del,NorCOMM-del,".
      #  "UCD EP,Helmholtz EP,Sanger EP,high priority"."\n";
        "Comment,MGI ID,Symbol,Chr,".
        "Conditionals,Targeted trap,Deletion,".
        "IKMC Microinj,IKMC mice,Last MI date,IKMC centre(s),".
        "Other mice - targeted,Other mice - cond,Lethality (MP:0010768),pubs,GO count,".
        "CSD status,REGN status,EUCOMM status,NorCOMM status,".
        "CSD-cond,CSD-tt,CSD-del,EUCOMM-cond,EUCOMM-tt,mirKO-del,Reg-Del,NorCOMM-del,".
        "UCD EP,Helmholtz EP,Sanger EP"."\n";
        
    foreach my $mgi_accession (keys %$master_genelist){
        # my @annots = @{$annotated_mgp_genes->{$mgi_accession}};
        my $g = $master_genelist->{$mgi_accession};
        my $t = $g->{products} || {};
        my $m = $g->{mice} || {};
        # my $u = $g->{ucd} || {};
        my $mi_date = $m->{microinjection_date};
        my $printed_date ='';
        if($mi_date){
           $printed_date = $mi_date->date;
        }
        my $p = $g->{pheno} || {};
        my $go = $g->{go_count} || {};
        my $go_count = scalar(keys %{$go});
        my @centres = keys(%{$m->{centres}});
        
        #fix the Deletion count (if it's missing) by using the regeneron status
        if(!$t->{Deletion}){
            if($g->{reg} eq 'ES cell colonies screened / QC positives'){
                $t->{Deletion} = '>1';
                $t->{'KOMP-Regeneron'}->{Deletion} = '>1';
            }elsif($g->{reg} eq 'ES cell colonies screened / QC one positive'){
                $t->{Deletion} = '1';
                $t->{'KOMP-Regeneron'}->{Deletion} = '1';
            }
        }
        
        my $exclusion = '';
        
        if (!($t->{'Conditional Ready'} || $t->{'Targeted Non Conditional'} || $t->{Deletion})){
            $exclusion = 'No Targeted ES cells'; 
        }
        
        if($go_count > 3 && ($t->{'Conditional Ready'} || $t->{'Targeted Non Conditional'} || $t->{Deletion})){
            $exclusion = 'GO';
        }
        
        #If non-IKMC mice exist and they are lethal, BUT we have conditionals
        if($p->{lethal_count} && $t->{'Conditional Ready'} && !$p->{targeted}){
            $exclusion = 'Other mice (lethal)';
        }
        if($p->{lethal_count} && $t->{'Conditional Ready'} && $p->{targeted}){
            $exclusion = 'Other mice (targeted - lethal)';
        }
        #If we have no IKMC - or other conditional -mice, but the resource has only tt's
        if((!$t->{Deletion}) && $t->{'Targeted Non Conditional'} && (!$t->{'Conditional Ready'})){
            $exclusion = 'Targeted trap only';
        }
        #If non-IKMC conditionals exist
        if($p->{conditional}){
            $exclusion = 'Other mice (cond.)';
        }
        #If kermits mice or UCD mice are in progress
        # if($m->{count} || ($u->{mi} || $u->{esc})){
        if ( $m->{count} ){
            $exclusion = 'IKMC in progress';
        }
        #If kermits mice have been genotyped
        # if($m->{distribute} || ($g->{'reg'} eq 'Germline Transmission Achieved') || ($u->{mice})){
        if ( $m->{distribute} || ( $g->{'reg'} eq 'Germline Transmission Achieved' ) ){
            $exclusion = 'IKMC mice';
        }
        

        print
            # "@annots,$exclusion,".$mgi_accession.','.$g->{marker}.','.$g->{chr}.','.
            
            # $t->{'Conditional Ready'}.','.$t->{'Targeted Non Conditional'}.','.$t->{Deletion}.','.
            
            # $u->{mice}.','.$u->{mi}.','.
            
            # $m->{count}.','.$m->{distribute}.",$mi_date,@centres,".
            
            # $p->{targeted}.','.$p->{conditional}.','.$p->{lethal_count}.','.$p->{pubs}.",$go_count,".
            
            # $g->{csd}.','. $g->{reg}.','.$g->{eucomm}.','.$g->{norcomm}.','.
            
            # $t->{'KOMP-CSD'}->{'Conditional Ready'}.','.$t->{'KOMP-CSD'}->{'Targeted Non Conditional'}.','.
            # $t->{'KOMP-CSD'}->{Deletion}.','.
            # $t->{'EUCOMM'}->{'Conditional Ready'}.','.$t->{'EUCOMM'}->{'Targeted Non Conditional'}.','.
            # $t->{'mirKO'}->{Deletion}.','.
            # $t->{'KOMP-Regeneron'}->{Deletion}.','.
            # $t->{NorCOMM}->{Deletion}.','.
            # $t->{depd_count}.','.$t->{hepd_count}.','.$t->{epd_count}.','.
            # $g->{high_priority}.
            # "\n";
        "$exclusion,".$mgi_accession.','.$g->{marker}.','.$g->{chr}.','.
            
            $t->{'Conditional Ready'}.','.$t->{'Targeted Non Conditional'}.','.$t->{Deletion}.','.
            
            $m->{count}.','.$m->{distribute}.",$mi_date,@centres,".
            
            $p->{targeted}.','.$p->{conditional}.','.$p->{lethal_count}.','.$p->{pubs}.",$go_count,".
            
            $g->{csd}.','. $g->{reg}.','.$g->{eucomm}.','.$g->{norcomm}.','.
            
            $t->{'KOMP-CSD'}->{'Conditional Ready'}.','.$t->{'KOMP-CSD'}->{'Targeted Non Conditional'}.','.
            $t->{'KOMP-CSD'}->{Deletion}.','.
            $t->{'EUCOMM'}->{'Conditional Ready'}.','.$t->{'EUCOMM'}->{'Targeted Non Conditional'}.','.
            $t->{'mirKO'}->{Deletion}.','.
            $t->{'KOMP-Regeneron'}->{Deletion}.','.
            $t->{NorCOMM}->{Deletion}.','.
            $t->{depd_count}.','.$t->{hepd_count}.','.$t->{epd_count}.
            "\n";
    }
}

sub get_master_genelist {
    DEBUG( "Downloading master genelist" );
    my $tmp = File::Temp->new;
    LWP::Simple::getstore( $MASTER_GENELIST_URL, $tmp->filename );
    open (MASTER, "<".$tmp->filename) or die "cant open the master gene list file\n";
    my $master;
    my $marker_to_mgi = {};
    
    while(<MASTER>){
        my ($mgi_accession,$marker_symbol,$chr,$start,$end,$strand,$csd,$reg,$eucomm,$norcomm,$rest) = split/\t/;
        # next unless $annotated_mgp_genes->{$mgi_accession};
        $master->{$mgi_accession} = {
            mgi => $mgi_accession,
            marker => $marker_symbol,
            chr => $chr,
            csd => $csd,
            reg => $reg,
            eucomm => $eucomm,
            norcomm => $norcomm,
        };
        $marker_to_mgi->{$marker_symbol} = $mgi_accession;
    }
    
    return ($master,$marker_to_mgi);
}

sub get_pheno_allele_data {
    DEBUG( "Downloading phenotypic allele data" );
    my $tmp = File::Temp->new;
    LWP::Simple::getstore( $PHENO_ALLELE_URL, $tmp->filename );
    open (PHENO, "<".$tmp->filename) or die "cant open the phenotypic allele file\n";
    my $pheno_allele_data;
    while(<PHENO>){
        my ($allele,$allele_symbol,$allele_name,$allele_type,$pubmed,$mgi_accession,$marker,$refseq,$ens,$mp_terms,$synonyms) = split/\t/;
        next unless (($allele =~ /MGI/) && ($mgi_accession =~ /MGI/));
        my $lethal;
        my $targeted;
        my $conditional;
        my $pub;
        if($mp_terms && ($mp_terms =~ /MP:0010768/)){
            $pheno_allele_data->{$mgi_accession}->{lethal_count}++;
        }
        if($allele_type && ($allele_type eq 'Targeted (Floxed/Frt)')){
            $pheno_allele_data->{$mgi_accession}->{conditional}++;
        }elsif($allele_type =~ /Targeted/){
            $pheno_allele_data->{$mgi_accession}->{targeted}++;
        }
        if($pubmed){
            $pheno_allele_data->{$mgi_accession}->{pubs}++;
        }
    }
    return $pheno_allele_data;
}

sub get_microinjections {
    my $qf = shift;

    DEBUG( "Querying biomart for microinjection data" );
    my $q = $qf->query(
        {
            dataset    => 'imits',
            attributes => [ qw( mgi_accession_id pipeline production_centre microinjection_status emma is_active microinjection_date) ]
        }
    );
    
    my $microinjections_for;

    for my $r ( @{ $q->results } ) {
        DEBUG( "Got microinjection data for $r->{mgi_accession_id}" );
        next unless ($r->{mgi_accession_id});
        next unless ($r->{is_active});
        next unless ($r->{microinjection_date});
        my $current_mi_date = DateTime::Format::Flexible->parse_datetime( $r->{microinjection_date} );
        my $best_mi_date = $microinjections_for->{$r->{mgi_accession_id}}->{microinjection_date};
        if($best_mi_date){
            if($current_mi_date > $best_mi_date){
                $microinjections_for->{$r->{mgi_accession_id}}->{microinjection_date} = $current_mi_date;
            }
        }else{
            $microinjections_for->{$r->{mgi_accession_id}}->{microinjection_date} = $current_mi_date;
        }
        
        $microinjections_for->{$r->{mgi_accession_id}}->{count}++;
        $microinjections_for->{$r->{mgi_accession_id}}->{centres}->{$r->{production_centre}} = 1;
        if($r->{emma}){
            $microinjections_for->{$r->{mgi_accession_id}}->{distribute}++;
        }
    }

    return $microinjections_for;
}

sub get_targ_rep_products {
    my $qf = shift;

    DEBUG( "Querying BioMart for targeted products" );
    
    my $q = $qf->query(         
        {
            dataset    => 'idcc_targ_rep',
            attributes => [ qw( mgi_accession_id pipeline ikmc_project_id escell_clone mutation_type ) ]
        }
    );

    my %products_for;
    
    for my $r ( @{ $q->results } ) {
        if ( $r->{escell_clone} ) {
            DEBUG( "Got $r->{pipeline}/$r->{mutation_type} product for $r->{mgi_accession_id}" );
            $products_for{ $r->{mgi_accession_id} } { $r->{pipeline} }{ $r->{mutation_type} }++;
            $products_for{ $r->{mgi_accession_id} } { $r->{mutation_type} }++;
            if($r->{escell_clone} =~ /DEPD/){
                $products_for{ $r->{mgi_accession_id}}->{depd_count}++;
            }elsif($r->{escell_clone} =~ /HEPD/){
                $products_for{ $r->{mgi_accession_id}}->{hepd_count}++;
            }elsif($r->{escell_clone} =~ /^EPD/){
                $products_for{ $r->{mgi_accession_id}}->{epd_count}++;
            }
        }           
    }

    return \%products_for;
}

sub get_go_annotations {
    DEBUG( "Downloading mgi gene ontology data" );
    my $tmp = File::Temp->new;
    LWP::Simple::getstore( $MGI_GO_URL, $tmp->filename );
    open (GO, "<".$tmp->filename) or die "can't open phenotypic allele file\n";
    my $go_counts = {};
    # open (GO, "<$MGI_GO_FILE") or die "cant open mgi go file $MGI_GO_FILE\n";
    while(<GO>){
        chomp;
        my ($first, $mgi_accession_id, $marker, $jnk1, $go_term_id, $rest) = split /\t/;
        next unless $mgi_accession_id =~ /MGI/;
        $go_counts->{$mgi_accession_id}->{$go_term_id} = 1;
    }
    return $go_counts;
}

sub get_ucd_injection_data {
    my $marker_to_mgi = shift;
    my $pilot_data = {};
    open (UCD,"<$UCD_FILE") or die "cant open UCD pilot data $UCD_FILE\n";
    while(<UCD>){
        chomp;
        my ($tmp, $marker, $project, $epd, $status) = split/,/;
        my $mgi_accession_id = $marker_to_mgi->{$marker};
        if(!$marker){warn "missed marker $marker"; next}
        if($status eq 'Germline transmission confirmed'){
            $pilot_data->{$mgi_accession_id}->{mice}++;
        }elsif($status eq 'Invitro QC Complete'){
            $pilot_data->{$mgi_accession_id}->{mi}++;
        }elsif($status eq 'Microinjection complete'){
            $pilot_data->{$mgi_accession_id}->{mi}++;
        }elsif($status eq 'Microinjection in progress'){
            $pilot_data->{$mgi_accession_id}->{mi}++;
        }elsif($status eq 'Germline testing'){
            $pilot_data->{$mgi_accession_id}->{mi}++;
        }
    }
    return $pilot_data;
}

#sub get_high_priority_genes {
#    my $priority_genes;
#    open (PRIORITY,"<$PRIORITY") or die "cant open high priority gene data $PRIORITY\n";
#    while(<PRIORITY>){
#        chomp;
#        my ($mgi_locus, $rest) = split /,/;
#        $priority_genes->{$mgi_locus} = 1;
#    }
#    open (HTGT,"<$EUCOMM_KOMP_PRIORITY_IN_HTGT") or die "cant open htgt priority data $EUCOMM_KOMP_PRIORITY_IN_HTGT\n";
#    while(<HTGT>){
#        chomp;
#        my ($mgi_locus) = split /,/;
#        $priority_genes->{$mgi_locus} = 1;
#    }
#    my @genes = keys (%$priority_genes);
#    return \@genes;
#}

#sub get_annotated_mgp_genes {
#    open (MGP_GENES, "<$MGP_GENES") or die "cant open file $MGP_GENES\n";
#    my $annotated_genes;
#    while(<MGP_GENES>){
#        chomp;
#        my ($source, $original, $transform, $mgi_acc) = split /\t/;
#        next if $mgi_acc eq '?';
#        $original |= '';
#        $transform |= '';
#        die "annotated mgp list must have source and mgi_accession" unless ($source && $mgi_acc);
#        my $annotation = $source.':'.$original . ':'. $transform . ':' . $mgi_acc;
#        push @{$annotated_genes->{$mgi_acc}}, $annotation;
#    }
#    return $annotated_genes;
#}

__END__
