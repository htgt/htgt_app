#!/usr/bin/env perl 
use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use IO::File;
use Text::CSV_XS;
use HTGT::Utils::IdccTargRep;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init( { level => $INFO, layout => '%p - %m%n' } );

GetOptions(
    'help'   => \my $help,
    'file=s' => \my $file
) or pod2usage(2);

pod2usage(1) if $help;

# read the downloaded file and store in a hash
my $fh   = IO::File->new( $file, O_RDONLY ) or die "cannot open the file $!\n";
my $data = parse_file($fh);
my %data = %{$data};
my $updated_gene_count = 0;
my $updated_allele_count = 0;

# initialise IdccTargRep instance for doing update later on
my $targrep = HTGT::Utils::IdccTargRep->new_with_config();

foreach my $id ( keys %data ) {
    if ( $id ne $data{$id} ) {
        # find the allele with the old id in targrep
        my $allele_rf = $targrep->find_allele( { mgi_accession_id => $id } );
        my @alleles = @$allele_rf;
        if ( scalar(@alleles) > 0 ) {
            foreach my $allele (@alleles) {
                # update allele
		print "update allele $allele->{id} from $id => $data{$id} \n";
                $targrep->update_allele( $allele->{id}, { mgi_accession_id => $data{$id} } );
		$updated_allele_count++;
            }
            $updated_gene_count++;
        }
    }
}

print "Total updated genes: $updated_gene_count\n";
print "Total updated alleles: $updated_allele_count \n";

sub parse_file {
    my $file = shift;
    my $csv  = Text::CSV_XS->new();
    my %data;

    while ( my $row = $csv->getline($file) ) {
        next unless ( $row->[0] =~ /^MGI:/ );
        my $old_id = $row->[0];
        my $new_id = $row->[2];
        $data{$old_id} = $new_id;
    }
    return \%data;
}

__END__

=head1 NAME

update_targrep_mgi_accession_id.pl

=head1 SYNOPSIS

    perl update_targrep_mgi_accession_id.pl --file filename 

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
