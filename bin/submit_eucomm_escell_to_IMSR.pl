#!/usr/bin/env perl
# scripts for retrieving data from Targrep and HTGT, then write to a tab-delimited text format file.

use strict;
use warnings FATAL => 'all';

use HTGT::Utils::IdccTargRep;
use HTGT::DBFactory;
use HTGT::Utils::ESCellStrain;

use Data::Dumper;
use Log::Log4perl qw/:easy/;
Log::Log4perl->easy_init( $DEBUG );
use LWP::UserAgent;
use JSON;

my $targrep = HTGT::Utils::IdccTargRep->new_with_config();
my $page = 1;

my $schema = HTGT::DBFactory->connect('eucomm_vector');

while (1){
    my $alleles = $targrep->find_allele({
	page => $page,
	pipeline_id => 4
    });
    last unless @$alleles;
    process_alleles($alleles);
    $page++;
}

sub process_alleles {
    my $alleles = shift;

    foreach my $alle (@$alleles){
	# search for es cell
	my $es_cell = $targrep->find_es_cell(
	    {
		allele_id => $alle->{id}
	    }
	);
	
	# get the es cell
	if( scalar(@$es_cell) > 0 ){
	    my $project_id;
	    my $es_cell_line;
	    my $es_cell_name;
	    
	    my $mgi_accession_id = $alle->{mgi_accession_id};
	    my $mgi_symbol = get_mgi_symbol($mgi_accession_id) || '';
	    
	    my %data;
	    
	    foreach my $ec (@$es_cell){
		$project_id = $ec->{ikmc_project_id};
		
		$es_cell_name = $ec->{name};
		
		# collect allele name & mgi_allele_id & es cell line here 
		if( $ec->{allele_symbol_superscript} ){
		    my $allele_name = $mgi_symbol."<".$ec->{allele_symbol_superscript}.">";
		    if( exists $data{$allele_name}{mgi_allele_id} and $data{$allele_name}{mgi_allele_id} ne ''){
			next;
		    }else{
			if( $ec->{mgi_allele_id} ){
			    $data{$allele_name}{mgi_allele_id} = $ec->{mgi_allele_id};
		        }else{
			    $data{$allele_name}{mgi_allele_id} = '';
			}
		    }
		    
		    if( $ec->{parental_cell_line} ){
			if( exists $data{$allele_name}{es_cell_line} ){
		            next;
			}else{
			    $data{$allele_name}{es_cell_line} = $ec->{parental_cell_line};
			}
		    }		    
		   
		    if( exists $data{$allele_name}{es_cell_name} and $data{$allele_name}{es_cell_name} ne ''){
			next;
		    }else{
			if ( $ec->{name} ){
			    $data{$allele_name}{es_cell_name} = $ec->{name};
			}else{
			    $data{$allele_name}{es_cell_name} = '';
			}
		    }
		    
		}
		
	    }
	    
	    # could be more than 1 allele
	    foreach my $allele_name ( keys %data ){
		if ( exists $data{$allele_name}{es_cell_line} and !( $data{$allele_name}{es_cell_name} =~ /mirKO/ )){
		    my $strain = es_cell_strain( $data{$allele_name}{es_cell_line} );	
		    print $alle->{id}."\t";
		    print $strain."-".$allele_name."\t";	
		    print "MSR\t";
		    print "ES\t";
		    print "http://www.knockoutmouse.org/martsearch/project/".$project_id."\t";
		    print $data{$allele_name}{mgi_allele_id}."\t";
		    print "\t";
		    print $allele_name."\t";
		    print "TM\t";
		    print $alle->{chromosome}."\t";
		    print $alle->{mgi_accession_id}."\t";
		    print $mgi_symbol."\t";
		    print "\n";
		}
	    }	   
	}
    }
}

sub get_mgi_symbol {
    my $mgi_accession_id = shift;
    
    my $ua = LWP::UserAgent->new();
    $ua->proxy('http', 'http://wwwcache.sanger.ac.uk:3128');
    
    my $url = "http://www.sanger.ac.uk/mouseportal/solr/select?q=$mgi_accession_id&wt=json";
    my $response = $ua->get( $url );
    die "Couldn't get gene symbol from $url" unless defined $response;
    
    if ( defined $response->content ){
	my $results = from_json( $response->content );
	return $results->{response}{docs}[0]{marker_symbol};
    }else{
	return "";
    }
}