#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/update_mgi_gene_marker_symbols.pl $
# $LastChangedDate: 2010-01-08 11:08:11 +0000 (Fri, 08 Jan 2010) $
# $LastChangedRevision: 733 $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use HTGT::DBFactory;
use Log::Log4perl ':easy';
use LWP::UserAgent;
use Pod::Usage;
use Readonly;

Readonly my $PROXY_URI      => 'http://wwwcache.sanger.ac.uk:3128/';
Readonly my $MGI_REPORT_URI => 'ftp://ftp.informatics.jax.org/pub/reports/MRK_List1.rpt';

my ( $schema, $commit );

sub init {

    my $loglevel = $WARN;
    my $logfile  = 'STDERR';

    GetOptions(
        'help' => sub { pod2usage( -verbose => 1 ) },
        'man'  => sub { pod2usage( -verbole => 2 ) },
        'debug'        => sub { $loglevel = $DEBUG },
        'verbose'      => sub { $loglevel = $INFO },
        'logfile=s'    => sub { $logfile  = '>>' . $_[ 1 ] },
        'commit'       => \$commit,
    ) or pod2usage( 2 );

    Log::Log4perl->easy_init(
        {
            level   => $loglevel,
            logfile => $logfile,
            layout  => '%p - %m%n'
        }
    );

    $schema = HTGT::DBFactory->connect( 'eucomm_vector' );
}

sub fetch_mgi_marker_symbols {
    my $ua = LWP::UserAgent->new();
    $ua->proxy( [ 'http', 'https', 'ftp' ] => $PROXY_URI );
    my $response = $ua->get( $MGI_REPORT_URI );
    unless ( $response->is_success() ) {
        die "failed to fetch $MGI_REPORT_URI: " . $response->status_line . "\n";
    }
    parse_mgi_marker_symbols( $response->content_ref );
}

sub parse_mgi_marker_symbols {
    my ( $content_ref ) = @_;

    my %sym_for;
    foreach ( split "\n", ${ $content_ref } ) {
        my ( $mgi_id, $marker_symbol ) = ( split "\t", $_ )[ 0, 3 ];
        next unless $mgi_id =~ /^MGI:\d+$/;
        if ( $sym_for{ $mgi_id } and $sym_for{ $mgi_id } ne $marker_symbol ) {
            die "inconsistent symbols for $mgi_id: '$sym_for{ $mgi_id }' ne '$marker_symbol'\n";
        }
        $sym_for{ $mgi_id } = $marker_symbol;
    }
    
    return \%sym_for;
}

init();

my $marker_symbol_for = fetch_mgi_marker_symbols();

$schema->txn_do( sub {
    my $mgi_genes = $schema->resultset( 'HTGTDB::MGIGene' )->search( {} );
    while ( my $mgi_gene = $mgi_genes->next ) {
        my $mgi_accession_id = $mgi_gene->mgi_accession_id;
        unless ( $mgi_accession_id ) {
            ERROR( "No MGI accession id for " . $mgi_gene->mgi_gene_id );
            next;
        }
        unless ( $marker_symbol_for->{ $mgi_accession_id } ) {
            INFO( "MGI did not supply marker symbol for $mgi_accession_id" );
            next;
        }
        my $marker_symbol = $mgi_gene->marker_symbol || '';
        if ( $marker_symbol_for->{ $mgi_accession_id } eq $marker_symbol ) {
            INFO( "Marker symbol for $mgi_accession_id unchanged: $marker_symbol" );
            next;
        }
        WARN( "Updating marker symbol for $mgi_accession_id: $marker_symbol => "
              . $marker_symbol_for->{ $mgi_accession_id } );
        $mgi_gene->update( { marker_symbol => $marker_symbol_for->{ $mgi_accession_id } } );
        foreach my $project ( $mgi_gene->projects ) {
            INFO( sprintf( "Project %s (status %s) impacted by %s marker_symbol change",
                           $project->project_id, $project->status->name, $mgi_accession_id ) );
        }
    }
    die "Rollback\n" unless $commit;
} );

__END__

=pod

=head1 NAME

update_mgi_gene_marker_symbols

=head1 SYNOPSIS

  update_mgi_gene_marker_symbols [OPTIONS]
  
=head1 OPTIONS

=over 4

=item B<--man>

=item B<--help>

=item B<--debug>

=item B<--verbose>

=item B<--production>
  
=item B<--commit>

=item B<--logfile>

=back

=head1 DESCRIPTION

This script fetches the latest list of MGI marker symbols from 
L<ftp://ftp.informatics.jax.org/pub/reports/> and compares this against
the C<mgi_gene> table, updating C<marker_symbol> where necessary.

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>

=cut

