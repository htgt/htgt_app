#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use List::MoreUtils qw(none);
use HTGT::DBFactory;
use IO::File;
use Text::CSV_XS;

my @columns = qw /
   WELL_ID WELL_NAME DESIGN_TYPE LOSS_OF_ALLELE THREEP_LOXP_SRPCR FIVEP_LOXP_SRPCR LATEST_TEST_COMPLETION_DATE
/;

#my $handle = IO::File->new( 'wells_with_loa_pass_and_failing_clone.csv', 'w');
my $handle = \*STDOUT;

my $parser = Text::CSV_XS->new( { eol => "\n" });
$parser->print( $handle, [@columns] );

my $schema = HTGT::DBFactory->connect('eucomm_vector' );

my @repository_qc = $schema->resultset('HTGTDB::RepositoryQCResult')->search( {
    'loss_of_allele' => 'pass' },
      {	prefetch => 'well'
      }   
    );

foreach my $r (@repository_qc){
    my @wds = $schema->resultset('HTGTDB::WellData')->search( { well_id=> $r->well_id } )->all;
    if ( ( none { $_->data_type eq 'distribute'} @wds ) and ( none { $_->data_type eq 'targeted_trap'} @wds ) ){
	my $di = $schema->resultset('HTGTDB::DesignInstance')->find(
	    { design_instance_id => $r->well->design_instance_id },
	    { prefetch => 'design' }
	);
	my $design_type = $di->design->design_type;
        
	$parser->print(
	    $handle, [
		$r->well_id,
		$r->well->well_name,
		$design_type,
		$r->loss_of_allele,
		$r->threep_loxp_srpcr,
		$r->fivep_loxp_srpcr,
		$r->latest_test_completion_date
	  ]		       
        );
    }
}


