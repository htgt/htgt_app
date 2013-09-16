#! /usr/bin/env perl

use strict;
use warnings FATAL => "all";
use Getopt::Long;
use Data::Compare;
use Data::Dumper::Concise;
use HTGT::DBFactory;
use HTGT::Utils::IdccTargRep;
use HTGT::Utils::MutagenesisPrediction::FloxedExons qw( get_floxed_exons );
use IO::String;
use JSON;
use List::Compare;
use List::MoreUtils 'minmax';
use Log::Log4perl ":easy";
use REST::Client;
use Text::CSV_XS;
use Try::Tiny;
use Web::Scraper;

Log::Log4perl->easy_init;

=head1 SYNOPSIS

  regeneron_import.pl [OPTIONS]

=head1 DESCRIPTION

This script will update the KOMP-Regeneron data in the B<targ_rep>. It retrieves
a list of B<ES Cells> daily from reports at MGI and Velocigene and compares them 
to the contents of the B<targ_rep> database, performing create/delete/update 
actions as required to keep them in sync.

=head1 FUNCTIONS

=cut

my $TARG_REP_PIPELINE_ID          = 2;
my $HOMOLOGY_ARM_PADDING          = 15000;
my $VELOCIGENE_PARENTAL_CELL_LINE = 'VGB6';
my $allele_rpt_url                = 'ftp://ftp.informatics.jax.org/pub/reports/KOMP_Allele.rpt';
my $coordinates_url               = 'http://www.velocigene.com/komp/ko_coordinates';
my $local_files                   = undef;

GetOptions(
    'help|?'        => \my $help,
    'local_files!'  => \$local_files
);

my $es_cells_from_targ_rep  = download_es_cells_from_targ_rep();
my $es_cells_from_urls      = download_es_cells_from_urls( $coordinates_url, $allele_rpt_url, $local_files );
my $classifications         = compare_es_cell_lists( $es_cells_from_targ_rep, $es_cells_from_urls );

# print "\n\n";
# print Dumper($classifications);
# print "\n\n";
# 
# for (my $var = 0; $var < 4; $var++) {
#     print "From targ_rep:\n";
#     warn Dumper( $es_cells_from_targ_rep->{ $classifications->{update}->[$var] } );
#     print "\n\n";
#     print "From urls:\n";
#     warn Dumper( $es_cells_from_urls->{ $classifications->{update}->[$var] } );
#     print "\n\n";
# }
# 
# exit;

INFO( "targ_rep es_cell count: ", scalar keys %{$es_cells_from_targ_rep} );
INFO( "urls es_cell count    : ", scalar keys %{$es_cells_from_urls} );

# CRUD any diferences
my $idcc         = HTGT::Utils::IdccTargRep->new_with_config( username => 'regeneron', password => 'WPbjGHdG' );
my %function_for = (
    create => \&create_es_cell,
    delete => \&delete_es_cell,
    update => \&update_es_cell,
);

for my $task ( keys %{$classifications} ) {
    INFO( "ES Cells to $task: ", scalar @{ $classifications->{$task} } );

    for my $es_cell ( @{ $classifications->{$task} } ) {
        try   { $function_for{$task}->( $es_cell, $es_cells_from_urls, $idcc ); }
        catch { INFO( "[ERROR - Could not $task $es_cell]: $_" ); };
    }
}

INFO("finished processing");

exit 0;

=head2 create_es_cell( I<$name>, I<$es_cells_cache>, I<$idcc> ) -> Undef

Create an ES Cell in the targ_rep

=cut

sub create_es_cell {
    my ( $name, $es_cells_cache, $idcc ) = @_;
    
    INFO("creating ES Cell $name");
    
    my $allele  = find_create_update_allele( $es_cells_cache->{$name}, $idcc );
    my $tv      = find_create_update_targeting_vector( $allele->{id}, $es_cells_cache->{$name}, $idcc );
    my $es_cell = {
        allele_id                 => $allele->{id},
        targeting_vector_id       => $tv->{id},
        name                      => $name,
        parental_cell_line        => $es_cells_cache->{$name}{parental_cell_line},
        ikmc_project_id           => $es_cells_cache->{$name}{ikmc_project_id},
        allele_symbol_superscript => $es_cells_cache->{$name}{allele_symbol_superscript},
        pipeline_id               => $TARG_REP_PIPELINE_ID
    };

    if ( my $new_es_cell = $idcc->create_es_cell($es_cell) ) {
        INFO("created ES Cell '$name' ($new_es_cell->{id})");
    }
    else {
        INFO("could not create ES Cell '$name'");
    }
}

=head2 delete_es_cell( I<$name>, I<$es_cells_cache>, I<$idcc> ) -> Undef

Delete an ES Cell in the targ_rep

=cut

sub delete_es_cell {
    my ( $name, $es_cells_cache, $idcc ) = @_;
    
    INFO("deleting ES Cell $name");
    
    my @es_cells = @{ $idcc->find_es_cell( { name => $name } ) };
    unless ( @es_cells == 1 ) { INFO("ES Cell $name does not exists"); return; }
    
    if ( $idcc->delete_es_cell( $es_cells[0]->{id} ) ) { INFO("deleted ES Cell '$name' ($es_cells[0]->{id})"); }
    else                                               { INFO("could not delete ES Cell '$name'"); }
    
    my $targeting_vector_id = $es_cells[0]->{targeting_vector_id};
    for my $dependant (qw( es_cell )) {
        my $find_method = "find_$dependant";
        if ( @{ $idcc->$find_method( { targeting_vector_id => $targeting_vector_id } ) } >= 1 ) {
            return;
        }
    }
    INFO "deleted targeting vector $targeting_vector_id" if $idcc->delete_targeting_vector($targeting_vector_id);
    
    my $allele_id = $es_cells[0]->{allele_id};
    for my $dependant (qw( es_cell targeting_vector )) {
        my $find_method = "find_$dependant";
        if ( @{ $idcc->$find_method( { allele_id => $allele_id } ) } >= 1 ) {
            return;
        }
    }
    INFO "deleted allele $allele_id" if $idcc->delete_allele($allele_id);
}

=head2 update_es_cell( I<$name>, I<$es_cells_cache>, I<$idcc> ) -> Undef

Update an ES Cell in the targ_rep

=cut

sub update_es_cell {
    my ( $name, $es_cells_cache, $idcc ) = @_;

    INFO("updating ES Cell $name");

    if ( my ($es_cell) = @{ $idcc->find_es_cell( { name => $name } ) } ) {
        my $allele        = find_create_update_allele( $es_cells_cache->{$name}, $idcc );
        my $tv            = find_create_update_targeting_vector( $allele->{id}, $es_cells_cache->{$name}, $idcc );
        my ($new_es_cell) = $idcc->update_es_cell(
            $es_cell->{id},
            {
                allele_id                 => $allele->{id},
                targeting_vector_id       => $tv->{id},
                name                      => $name,
                parental_cell_line        => $es_cells_cache->{$name}{parental_cell_line},
                ikmc_project_id           => $es_cells_cache->{$name}{ikmc_project_id},
                allele_symbol_superscript => $es_cells_cache->{$name}{allele_symbol_superscript},
                pipeline_id               => $TARG_REP_PIPELINE_ID
            }
        );

        INFO("updated ES Cell '$name' ($new_es_cell->{id})");
    } else {
        create_es_cell( $name, $es_cells_cache, $idcc );
    }
}

=head2 find_create_update_allele( I<$data>, I<$idcc> ) -> HashRef

Finds/creates/updates an allele for the given data

=cut

sub find_create_update_allele {
    my ( $data, $idcc ) = @_;
    
    # Calc the homology_arms
    if ( $data->{strand} eq "+" ) {
        $data->{homology_arm_start} = $data->{cassette_start} - $HOMOLOGY_ARM_PADDING;
        $data->{homology_arm_end}   = $data->{cassette_end} + $HOMOLOGY_ARM_PADDING;
    }
    else {
        $data->{homology_arm_start} = $data->{cassette_start} + $HOMOLOGY_ARM_PADDING;
        $data->{homology_arm_end}   = $data->{cassette_end} - $HOMOLOGY_ARM_PADDING;
    }
    
    my $allele = _find_allele( $data, $idcc );
    
    if ( defined $allele ) {
        $allele = _update_allele_if_needed( $data, $allele, $idcc );
    } else {
        $allele = _create_allele( $data, $idcc );
    }
    
    return $allele;
}

sub _find_allele {
    my ( $data, $idcc ) = @_;
    my $allele = {
        chromosome       => $data->{chromosome},
        cassette_start   => $data->{cassette_start},
        cassette_end     => $data->{cassette_end},
        mgi_accession_id => $data->{mgi_accession_id},
        design_type      => "Deletion"
    };

    my @alleles = @{ $idcc->find_allele($allele) };

    if    ( @alleles == 1 ) { return $alleles[0]; }
    elsif ( @alleles > 1 )  { die "Too many results found for ", Dumper $allele; }
    else                    { return undef; }
}

sub _create_allele {
    my ( $data, $idcc ) = @_;
    
    my $allele = {
        chromosome         => $data->{chromosome},
        cassette_start     => $data->{cassette_start},
        cassette_end       => $data->{cassette_end},
        homology_arm_start => $data->{homology_arm_start},
        homology_arm_end   => $data->{homology_arm_end},
        mgi_accession_id   => $data->{mgi_accession_id},
        design_type        => "Deletion",
        strand             => $data->{strand}
    };
    
    # Get the deleted exons
    try {
        my $ens_gene_id = search_solr_index( $data->{mgi_accession_id} )->{ensembl_gene_id};
        if ( defined $ens_gene_id ) {
            my $floxed_exons = get_floxed_exons( $ens_gene_id, $allele->{cassette_start}, $allele->{cassette_end} );
            $allele->{floxed_start_exon} = $floxed_exons->[0];
            $allele->{floxed_end_exon}   = $floxed_exons->[-1];
        }
    }
    catch {
        die 'Problems trying to get floxed exon data: ' .  $_;
    };
    
    # Add in the cassette details...
    my $cas_details          = get_cassette_from_velocigene( $data->{ikmc_project_id} );
    $allele->{cassette}      = $cas_details->{cassette};
    $allele->{cassette_type} = $cas_details->{cassette_type};

    INFO( "Creating allele: ", Dumper $allele );
    
    return $idcc->create_allele($allele);
}

sub _update_allele_if_needed {
    my ( $data, $allele, $idcc ) = @_;
    
    my $old = {
        id                 => $allele->{id},
        strand             => $allele->{strand},
        mgi_accession_id   => $allele->{mgi_accession_id},
        cassette_end       => $allele->{cassette_end},
        cassette_start     => $allele->{cassette_start},
        chromosome         => $allele->{chromosome},
        homology_arm_start => $allele->{homology_arm_start},
        homology_arm_end   => $allele->{homology_arm_end}
    };

    my $new = {
        id                 => $allele->{id},
        strand             => $data->{strand},
        mgi_accession_id   => $data->{mgi_accession_id},
        cassette_end       => $data->{cassette_end},
        cassette_start     => $data->{cassette_start},
        chromosome         => $data->{chromosome},
        homology_arm_start => $data->{homology_arm_start},
        homology_arm_end   => $data->{homology_arm_end}
    };
        
    unless ( Compare( $old, $new ) ) {
        $new = $idcc->update_allele( $allele->{id}, $new );
        INFO "Updated allele ($new->{id})";
    }
    
    return $new;
}

=head2 find_create_update_targeting_vector( I<$allele_id>, I<$data>, I<$idcc> ) -> HashRef

Finds/creates/updates a targeting vector for the given data

=cut

sub find_create_update_targeting_vector {
    my ( $allele_id, $data, $idcc ) = @_;
    
    my $tv  = 0;
    my @tvs = @{ $idcc->find_targeting_vector({ name => $data->{targeting_vector} }) };
    if    ( @tvs == 1 ) { $tv = $tvs[0]; }
    elsif ( @tvs > 1 )  { die "Too many targeting vectors found for '$data->{targeting_vector}'"; }
    
    my $new_tv_data = {
        allele_id       => $allele_id,
        name            => $data->{targeting_vector},
        ikmc_project_id => $data->{ikmc_project_id},
        pipeline_id     => $TARG_REP_PIPELINE_ID
    };
    
    if ( $tv ) {
        my $old_tv_data = {
            allele_id       => $tv->{allele_id},
            name            => $tv->{name},
            ikmc_project_id => $tv->{ikmc_project_id},
            pipeline_id     => $TARG_REP_PIPELINE_ID
        };
        
        unless( Compare( $old_tv_data, $new_tv_data) ) {
            $tv = $idcc->update_targeting_vector( $tv->{id}, $new_tv_data );
            INFO("updated targeting vector '$data->{targeting_vector}'");
        }
    } else {
        if ( $tv = $idcc->create_targeting_vector($new_tv_data) ) {
            INFO("created targeting vector '$data->{targeting_vector}' ($tv->{id})");
        } else {
            INFO("unable to create targeting vector '$data->{targeting_vector}'");
        }
    }
    
    return $tv;
}

=head2 compare_es_cell_lists( I<$from_targ_rep>, I<$from_urls> ) -> HashRef

Compare the ES Cells from the data sources and classify them into create, delete and update lists

=cut

sub compare_es_cell_lists {
    my ( $from_targ_rep, $from_urls ) = @_;

    INFO("Working out which CRUD operations need to be performed");
    my $compare = List::Compare->new( [ keys %{$from_targ_rep} ], [ keys %{$from_urls} ] );

    return {
        create => [ $compare->get_complement ],
        delete => [ $compare->get_unique ],
        update => [ grep !Compare( $from_targ_rep->{$_}, $from_urls->{$_} ), $compare->get_intersection ]
    };
}

=head2 download_es_cells_from_targ_rep( ) -> HashRef

Downloads all the ES Cell data from the targ_rep

=cut

sub download_es_cells_from_targ_rep {
    INFO("Getting current contents of the targeting repository");
    
    my $results = {};
    my $dbh     = HTGT::DBFactory->dbi_connect( 'idcc' );
    my $sth     = $dbh->prepare(q[
        select
            a.mgi_accession_id,
            a.cassette_start,
            a.cassette_end,
            a.chromosome,
            a.strand,
            esc.ikmc_project_id,
            tv.name as targeting_vector,
            esc.name as escell_clone,
            esc.parental_cell_line,
            esc.allele_symbol_superscript
        from
            pipelines p
            join targeting_vectors tv on tv.pipeline_id = p.id
            join alleles a            on tv.allele_id = a.id
            join es_cells esc         on esc.targeting_vector_id = tv.id
        where
            p.name = 'KOMP-Regeneron'
    ]);
    $sth->execute();
    
    while ( my $row = $sth->fetchrow_hashref ) {
        $results->{ $row->{escell_clone} } = $row;
    }
    
    return $results;
}

=head2 download_es_cells_from_urls( I<$coordinates>, I<$allele_info> ) -> HashRef

Download and process all the ES Cell data from the URLs

=cut

sub download_es_cells_from_urls {
    my ( $coordinates, $allele_info, $local_files ) = @_;
    my $parser         = Text::CSV_XS->new( { eol => "\n", sep_char => "\t" } );
    my $coordinates_FH = undef;
    my $allele_info_FH = undef;
    
    if ( $local_files ) {
        $coordinates_FH = _get_data_from_file($coordinates);
        $allele_info_FH = _get_data_from_file($allele_info);
    } else {
        $coordinates_FH = _get_data_from_url($coordinates);
        $allele_info_FH = _get_data_from_url($allele_info);
    }
    
    my %coordinates_for;
    
    while ( my $row = $parser->getline($coordinates_FH) ) {
        $coordinates_for{ 'VG' . $row->[0] } = {
            chromosome     => $row->[1],
            cassette_start => $row->[2],
            cassette_end   => $row->[3],
        };
    }

    my %es_cells;

    while ( my $row = $parser->getline($allele_info_FH) ) {
        if ( $row->[1] && $row->[1] eq 'KOMP-Regeneron-Project' ) {
            for my $name ( split /,/, $row->[7] ) {
                $row->[3] = $1 if $row->[3] =~ m/^.*\<(.*)\>.*$/;
                if ( $coordinates_for{ $row->[0] } ) {
                    $es_cells{$name} = {
                        ikmc_project_id           => $row->[0],
                        allele_symbol_superscript => $row->[3],
                        mgi_accession_id          => $row->[5],
                        targeting_vector          => $row->[0],
                        escell_clone              => $name,
                        parental_cell_line        => $VELOCIGENE_PARENTAL_CELL_LINE,
                        strand                    => search_solr_index($row->[5])->{strand}, %{ $coordinates_for{$row->[0]} }
                    };
                }
            }
        }
    }
    
    # Correct the strand and cassette start/end if needed...
    foreach my $escell_name ( keys %es_cells ) {
        my $data = $es_cells{$escell_name};
        
        # pseudogenes have no strand so lets work it out...
        unless ( $data->{strand} ) {
            $data->{strand} = $data->{cassette_start} < $data->{cassette_end} ? "+" : "-";
        }
        
        # Check and correct the coordinates based on strand...
        @{$data}{qw(cassette_start cassette_end)}
            = $data->{strand} eq "+"
            ? minmax @{$data}{qw(cassette_start cassette_end)}
            : reverse minmax @{$data}{qw(cassette_start cassette_end)};
        
        $es_cells{$escell_name} = $data;
    }
    
    return \%es_cells;
}

sub _get_data_from_url {
    my $url    = shift;
    my $client = REST::Client->new;
    
    INFO("Requesting data from $url");
    
    if ( $ENV{HTTP_PROXY} ) { $client->getUseragent->proxy( ['http'], $ENV{HTTP_PROXY} ); }

    $client->GET($url);

    unless ( $client->responseCode == 200 ) {
        die "Could not download data from [$url]: ", $client->responseCode;
    }

    return IO::String->new( $client->responseContent );
}

sub _get_data_from_file {
    my $url      = shift;
    my $filename = $1 if $url =~ /\/([\w\.]+)$/;
    
    INFO("Reading in data from local file: $filename");
    
    open FILE, $filename or die "Couldn't open file: $!";
    my $contents = join("", <FILE>);
    close FILE;
    
    return IO::String->new( $contents );
}


=head2 search_solr_index( I<$mgi_id> ) -> HashRef

Search the Solr index for the MGI gene id

=cut

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

=head2 get_cassette_from_velocigene( I<$velocigene_id> ) -> HashRef

Helper function to scrape the Velocigene website and collect the 
cassette for a given project.

=cut

sub get_cassette_from_velocigene {
    my $velocigene_id      = shift;
    $velocigene_id = $1 if $velocigene_id =~ m/VG(\d+)/;
    
    my $velocigene_url     = 'http://www.velocigene.com/komp/detail/' . $velocigene_id;
    my $velocigene_scraper = scraper {
        process "table#maid_details tr", "allele_details[]" => scraper {
            process "td.heading", heading => 'TEXT';
            process "td.data", data => 'TEXT';
        }
    };
    
    INFO("Requesting $velocigene_url (to get cassette information)");
    
    my $html_content   = _get_data_from_url( $velocigene_url )->string_ref;
    my $scraped_data   = $velocigene_scraper->scrape( $html_content );
    my %allele_details = map { $_->{heading} => $_->{data} } @{ $scraped_data->{allele_details} };
    
    die "Unable to fetch cassette information for VG$velocigene_id" unless defined $allele_details{'Cassette'};
    
    my $cassette          = $allele_details{"Cassette"};
    my $cassette_type_map = {
        'ZEN-UB1.GB' => 'Promotor Driven',
        'ZEN-Ub1'    => 'Promotor Driven',
        'TM-ZEN-UB1' => 'Promotor Driven',
        'TM-ZEN-Ub1' => 'Promotor Driven'
    };
    my $cassette_type     = $cassette_type_map->{$cassette};
    
    die "Found unrecognized cassette '$cassette' for VG$velocigene_id - please add to recognised cassettes!" unless defined $cassette_type;
    
    return { cassette => $cassette, cassette_type => $cassette_type }
}

=head1 SEE ALSO

=over 4

=item L<HTGT::DBFactory>

=item L<HTGT::Utils::IdccTargRep>

=back

=head1 AUTHORS

Nelo Onyiah <io1@sanger.ac.uk>,
Darren Oakley <do2@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Genome Research Ltd.

This is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language
system itself.

=cut
