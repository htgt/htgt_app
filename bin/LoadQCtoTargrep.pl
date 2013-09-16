#!/usr/bin/env perl
# scripts for loading htgt qc data to targrep

use strict;
use warnings FATAL => 'all';
use HTGT::DBFactory;
use HTGT::BioMart::QueryFactory;
use HTGT::Utils::IdccTargRep;
use Getopt::Long;
use Pod::Usage;

GetOptions(
    'help'          => \my $help,
    'start_clone=s' => \my $start_clone,
    'logfile=s'     => \my $log,
    'job_index=s'     => \my $job_index
) or pod2usage(2);

pod2usage(1) if $help;

if( defined $log){
    $log = '>'.$log;
}else{
    $log = 'STDERR';
}

use Log::Log4perl qw/:easy/;
Log::Log4perl->easy_init( { level => $INFO, file => $log, layout => '%p - %m%n' } );

my $targrep = HTGT::Utils::IdccTargRep->new_with_config();

my $qf =
  HTGT::BioMart::QueryFactory->new(
    martservice => 'http://www.i-dcc.org/biomart/martservice' );

my $q = $qf->query(
    {
        dataset    => 'idcc_targ_rep',
        filter     => { 'pipeline' => 'KOMP-CSD,EUCOMM' },
        attributes => [qw/escell_clone/]
    }
);

my $es_cell_ref = $q->results;

my $schema = HTGT::DBFactory->connect('eucomm_vector');

my @es_cell_list;

# remove any undef rows or non htgt type es cells
foreach my $cell (@$es_cell_ref) {
    if ( $cell->{escell_clone} ) {
        push @es_cell_list, $cell;
    }
    else {
        next;
    }
}

# sort the list
my @sorted_es_cell_list =
  sort { $a->{escell_clone} cmp $b->{escell_clone} } @es_cell_list;

# check where to start process the list
my $start;
if ($start_clone) {
    $start = 0;
}
else {
    $start = 1;
}

my $total_updated = 0;
my $num_not_in_htgt = 0;
my $num_not_in_targrep = 0;
my $num_went_wrong = 0;

foreach my $c (@sorted_es_cell_list) {
    my $clone_name = $c->{escell_clone};

    # if the start_clone define, then we need to find where to start
    if ( $start == 0 ) {
        if ( $c->{escell_clone} ne $start_clone ) {
            next;
        }
        else {
            $start = 1;
            INFO("found start clone " . $c->{escell_clone});
        }
    }

    if ( $start == 1 ) {
        if( $clone_name =~ /^(\w+_\d+)_(\w+)/ ){
	    my $plate_name = $1;
	    $plate_name =~ /^(\D+)(\d+)_(\d+)/;
	    my $epd_number = $2;
            my $clone_index = substr($epd_number, -1, 1);

	    if( $clone_index eq $job_index ){
		# find the clone in htgt
		my @htgt_well =
		  $schema->resultset('HTGTDB::Well')
		  ->search(
		    {  'plate.name' => $plate_name,
		       'well_name' => $clone_name		  
		    },
		    { join => 'plate' }
		);
		if ( scalar(@htgt_well) > 0 ) {
		    my $well = $htgt_well[0];
	
		    my $three_prime_qc = $well->three_arm_pass_level;
		    my $five_prime_qc  = $well->five_arm_pass_level;
		    my $loxp           = $well->loxP_pass_level;
		    INFO( "five prime qc: ". $five_prime_qc. " three prime qc: ". $three_prime_qc. " loxp: ". $loxp );
		    
		    # check if exists in targrep and find the id
		    my $tr_es_cell =
		      $targrep->find_es_cell( { name => $c->{escell_clone} } );
	
		    if ( scalar(@$tr_es_cell) > 0 ) {	                
			#convert into the vocalburies in targrep
			if ( $three_prime_qc eq 'na' ) {
			    $three_prime_qc = 'not attempted';
			}
			elsif ( $three_prime_qc eq 'nd' ) {
			    $three_prime_qc = 'no reads detected';
			}
	
			if ( $five_prime_qc eq 'na' ) {
			    $five_prime_qc = 'not attempted';
			}
			elsif ( $five_prime_qc eq 'nd' ) {
			    $five_prime_qc = 'no reads detected';
			}
	
			if ( $loxp eq 'na' ) {
			    $loxp = 'not attempted';
			}
			elsif ( $loxp eq 'nd' ) {
			    $loxp = 'no reads detected';
			}
			
			# retrieve es cell id
			my $escell_id = $tr_es_cell->[0]->{id};
			
			eval {
			    # update targrep
			    INFO( "updating " . $c->{escell_clone} . " ES CELL ID: " . $escell_id);
			    INFO( "five prime qc: ". $five_prime_qc. " three prime qc: ". $three_prime_qc. " loxp: ". $loxp );
			    $targrep->update_es_cell(
				$escell_id,
				{
				    production_qc_five_prime_screen  => $five_prime_qc,
				    production_qc_three_prime_screen => $three_prime_qc,
				    production_qc_loxp_screen        => $loxp
				}
			    );
			};
			if ($@) {
			    INFO( "### update WENT WRONG for ". $c->{escell_clone}." ".$@ );
			    $num_went_wrong++;
			    next;
			}
			$total_updated++;
		    }
		    else {
			INFO("not found es cell ". $c->{escell_clone}. " in targrep");
			$num_not_in_targrep++;
		    }
		}
		else {
		    INFO("not found es cell " . $c->{escell_clone} . " in htgt");
		    $num_not_in_htgt++;
		}
	    }else{
		next;
	    }
	}else{
	    INFO("cannot match the clone name\n");
	    next;
	}
    }
}

INFO("Total number updated: ".$total_updated);
INFO("Total number not found in htgt: ".$num_not_in_htgt);
INFO("Total number not found in targrep: ".$num_not_in_targrep);
INFO("Total number update went wrong: ".$num_went_wrong);

__END__

=head1 NAME

LoadQCtoTargrep.pl

=head1 SYNOPSIS

    perl LoadQCtoTargrep.pl --start_clone clone_name --logfile logfile_name --job_index job_index

=head1 AUTHOR

Wanjuan Yang , E<lt>wy1@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Genome Research Ltd

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
