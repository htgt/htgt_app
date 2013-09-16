use strict;
use warnings FATAL => 'all';

use IO::File;
use HTGT::Utils::IdccTargRep;

use Getopt::Long;
use Pod::Usage;
use Log::Log4perl ':easy';
use Text::CSV_XS;

GetOptions(
    'help' => \my $help,
    'file=s' => \my $file,
    'log=s'    => \my $logfile
) or pod2usage(2);

pod2usage(1) if $help;

Log::Log4perl->easy_init(
    {
	level => $INFO,
	file  => $logfile,
	layout => '%p - %m%n' 
    }
);

my $targrep = HTGT::Utils::IdccTargRep->new_with_config();

my $fh = IO::File->new( $file, O_RDONLY ) or die "can't open the file $!\n";

my $csv = Text::CSV_XS->new();

my %data;
my $total_count;
my $num_updated;

while ( not $fh->eof ){
    my $row = $csv->getline($fh) or die "csv parse error ";
    $total_count++;

    my $clone_id = $row->[0];
    my $qc_type = $row->[1];
    my $qc_result = $row->[2];

    if ($clone_id =~ /^\D+\d+_\d+_\D\d+/){
	if ( $qc_type =~ /3/ ){
	    if(exists  $data{$clone_id}{three_prime_qc} ){
		warn "more than one value for this clone $clone_id\n";
	    }
	    $data{$clone_id}{three_prime_qc} = $qc_result;
	}
	elsif( $qc_type =~ /5/ ){
	    if(exists $data{$clone_id}{five_prime_qc}){
		warn "more than one value for this clone $clone_id\n";
	    }
	    $data{$clone_id}{five_prime_qc} = $qc_result;
	}else{
	    INFO("not right type");
	}
    }else{
	INFO("$clone_id not match");
    }
}

foreach my $k (keys %data){
    my $tr_es_cell = $targrep->find_es_cell( { name => $k } );

    if ( scalar(@$tr_es_cell) > 0 ) {
	# retrieve es cell id
	my $escell_id = $tr_es_cell->[0]->{id};
	
	eval{
	     INFO("Updating $k ");
	     $num_updated++;
	     $targrep->update_es_cell(
		$escell_id,
		{  user_qc_five_prime_lr_pcr =>  $data{$k}{five_prime_qc},
		   user_qc_three_prime_lr_pcr => $data{$k}{three_prime_qc}
		}
	     );
	};
	if($@){
	    INFO("Update went wrong: $@");
	}
    }else{
	INFO("not found in targrep");
    }
}

INFO("Total parse data: ".$total_count);
INFO("Total data retrieved from file:".scalar(keys %data));
INFO("Total updated: ".$num_updated);


__END__

=head1 NAME

Load_user_qc_to_tr.pl

=head1 SYNOPSIS

    perl Load_user_qc_to_tr.pl --file inputfile --log logfile_name

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
