#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

#
#WARNING: Script does not check for existance of pseudogene comments so will add duplicate gene comments
#Need to fix this if you want to run it again.
#
use Getopt::Long;
use Pod::Usage;
use Const::Fast;
use HTGT::DBFactory;
use HTGT::Utils::EnsEMBL;
use HTGT::Utils::FileDownloader qw(download_url_to_tmp_file);
use Try::Tiny;
use Log::Log4perl ':easy';
use Data::Dumper::Concise;

const my $PSUEDOGENE_URL => 'http://tables.pseudogene.org/dump.cgi?table=Mouse60';

{
    my $log_level = $WARN;
    my $sa        = HTGT::Utils::EnsEMBL->slice_adaptor;
    my $htgt      = HTGT::DBFactory->connect( 'eucomm_vector' );
    
    GetOptions(
        'help'             => sub { pod2usage( -verbose => 1 ) },
        'man'              => sub { pod2usage( -verbose => 2 ) },
        'verbose'          => sub { $log_level = $INFO },
        'pseudogene-url=s' => \my $pseudogene_url,
        'not_env_proxy'    => \my $not_env_proxy,
        'commit'           => \my $commit,
    ) or pod2usage(2);
    Log::Log4perl->easy_init( { layout => '%p %m%n', level => $log_level } );
    my $env_proxy = $not_env_proxy ? 0 : 1;
    my $pseudogene_data_fh = download_url_to_tmp_file( $pseudogene_url || $PSUEDOGENE_URL, $env_proxy);
    $pseudogene_data_fh->getline; #remove first line
    
    my $genes = process_pseudogene_data( $htgt, $pseudogene_data_fh, $sa, $commit );
    print Dumper($genes);
}

sub process_pseudogene_data {
    my ( $htgt, $pseudogene_data_fh, $sa, $commit ) = @_;
    my @genes;

    while ( <$pseudogene_data_fh> ) {
        chomp;
        my $pseudogene_data = parse_pseudogene_record( $_, $sa ) or next;
        push @genes, @{ $pseudogene_data->{genes} };
        $htgt->txn_do(
           sub {       
               try {
                   add_pseudogene_data( $htgt, $pseudogene_data );
               }
               catch {
                   ERROR('processing ' . $pseudogene_data->{id} .  ': ' . $_);
               };
               
               $htgt->txn_rollback unless $commit;
           }
        );
    }
    return \@genes;
}

sub parse_pseudogene_record {
    my ( $input_line, $sa ) = @_;
    my %pseudogene_data;
    my @data                    = split /\s+/, $input_line;
    $pseudogene_data{id}        = $data[0];
    $pseudogene_data{parent_id} = $data[8];

    #Grab ensemble gene id
    my ( $chr, $start, $end ) = @data[1,2,3];
    my $slice = $sa->fetch_by_region( 'chromosome', $chr, $start, $end, 1 );
    my @genes = @{$slice->get_all_Genes};
    
    unless ( @genes ) {
        WARN('No genes found for given coordinates in: ' . $pseudogene_data{id}
             . " - Chromosome: $chr, Start: $start, End: $end");
        return;
    }
    my @gene_ids = map { $_->stable_id } @genes;
    $pseudogene_data{genes} = \@gene_ids;

    return \%pseudogene_data;
}


sub add_pseudogene_data {
    my ( $htgt, $pseudogene_data ) = @_;

    my $mgi_gene_rs = $htgt->resultset('MGIGene')->search_rs(
        {
            ensembl_gene_id => $pseudogene_data->{genes}
        }
    );
    
    if ( $mgi_gene_rs->count == 0 ) {
        WARN( join ',', @{$pseudogene_data->{genes}} . ' not present in mgi_gene table');
        return;
    }
    
    while ( my $mgi_gene = $mgi_gene_rs->next ) {
        INFO('Added pseudogene comment for mgi_gene: '
            . $mgi_gene->mgi_gene_id . ' ens id: ' . $mgi_gene->ensembl_gene_id );
        $mgi_gene->gene_comments->create(
            {
                visibility   => 'internal',
                edited_user  => $ENV{USER},
                gene_comment => 'Yale pseudogene prediction '
                                . $pseudogene_data->{id} . ', parent '
                                . $pseudogene_data->{parent_id},
            }
        );
    }
}

__END__

=head1 NAME

load_pseudogene_information.pl - Add pseudogene comment to htgt

=head1 SYNOPSIS

load_pseudogene_information.pl [options]

      --help             Display a brief help message
      --man              Display the manual page
      --verbose          Print info messages
      --pseudogene-url=s Specify a url for the Yale mouse pseudogene data (optional)
      --not_env_proxy    Do not use env proxy values for connection
      --commit           Run script in commit mode, making changes to the targ rep

There is a default url for the pseudogene data.
The env_proxy setting is on by default.

=head1 DESCRIPTION

Get Yale pseudogene information from their website and add a gene_comment for all
matching genes stating this gene has a Yale pseudogene predition.

=head1 AUTHOR

Sajith Perera

=head1 BUGS

If gene already has a yale pseudogene prediction comment the script will still add
another one, need to add a check for already existing pseudogene comments.

None reported... yet.

=cut