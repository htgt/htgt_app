#! /usr/bin/env perl

use strict;
use warnings FATAL => "all";
use Getopt::Long;
use Data::Compare;
use Data::Dumper::Concise;
use HTGT::DBFactory;
use HTGT::Utils::IdccTargRep;
use HTGT::Utils::MutagenesisPrediction::FloxedExons qw( get_floxed_exons );
use JSON;
use Log::Log4perl ":easy";
use REST::Client;

Log::Log4perl->easy_init;

my $TARG_REP_PIPELINE_ID = 2;
my $targ_rep_dbh         = HTGT::DBFactory->dbi_connect( 'idcc' );
my $targ_rep_service     = HTGT::Utils::IdccTargRep->new_with_config( username => 'regeneron', password => 'WPbjGHdG' );

INFO("Checking current Regeneron alleles and updating if needed...");

my $sth = $targ_rep_dbh->prepare(q[
    select distinct
        a.id,
        a.mgi_accession_id,
        a.cassette_start,
        a.cassette_end,
        a.floxed_start_exon,
        a.floxed_end_exon
    from
        pipelines p
        join targeting_vectors tv on tv.pipeline_id = p.id
        join alleles a            on tv.allele_id = a.id
    where
        p.name = 'KOMP-Regeneron'
]);
$sth->execute();

while ( my $row = $sth->fetchrow_hashref ) {
    INFO("Working on TargRep Allele ID: ".$row->{id});
    
    eval {
        my $ens_gene_id = search_solr_index( $row->{mgi_accession_id} )->{ensembl_gene_id};
        if ( defined $ens_gene_id ) {
            my $old_start_exon = $row->{floxed_start_exon} ? $row->{floxed_start_exon} : '';
            my $old_end_exon   = $row->{floxed_end_exon} ? $row->{floxed_end_exon} : '';

            my $floxed_exons   = get_floxed_exons( $ens_gene_id, $row->{cassette_start}, $row->{cassette_end} );
            my $new_start_exon = $floxed_exons->[0];
            my $new_end_exon   = $floxed_exons->[-1];

            if ( defined $new_start_exon && defined $new_end_exon ) {
                unless ( $old_start_exon eq $new_start_exon && $old_end_exon eq $new_end_exon ) {
                    $targ_rep_service->update_allele(
                        $row->{id},
                        { floxed_start_exon => $new_start_exon, floxed_end_exon => $new_end_exon }
                    );
                }
            }
        }
    };
    if ($@) {
        die 'Problems trying to get floxed exon data: ' .  $@;
    };

}

# done
exit;

sub search_solr_index {
    my $mgi_id = shift;
    my $client = REST::Client->new();
    my $url    = "http://htgt.internal.sanger.ac.uk:8983/solr/select?wt=json&q=";

    $client->GET( $url . $mgi_id );

    if ( $client->responseCode == 200 ) {
        my $response = from_json( $client->responseContent )->{response};
        my @results  = grep( $_->{mgi_accession_id} eq $mgi_id, @{ $response->{docs} } );

        unless ( @results == 1 ) {
            die "Found ", scalar(@results), " solr entries for $mgi_id";
        }

        my @ens_gene_ids = grep( /ENSMUSG/, @{ $results[0]->{ensembl_gene_id} } );

        return {
            ensembl_gene_id => $ens_gene_ids[0],
            chromosome      => $results[0]->{chromosome},
            end             => $results[0]->{coord_end},
            start           => $results[0]->{coord_start},
            strand          => $results[0]->{strand},
        };
    }

    die "Could not fetch data for $mgi_id";
}
