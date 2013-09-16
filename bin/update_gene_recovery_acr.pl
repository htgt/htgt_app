#!/usr/bin/env perl
# update_gene_recovery_acr.pl --- update the gene_recovery table with latest alternate clone recovery data
# Author: Ray Miller <rm7@sanger.ac.uk>
# Created: 18 Feb 2010
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/update_gene_recovery_acr.pl $
# $LastChangedRevision: 1181 $
# $LastChangedDate: 2010-03-01 15:25:02 +0000 (Mon, 01 Mar 2010) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use Log::Log4perl ':easy';
use IO::File;
use List::MoreUtils 'uniq';
use Text::CSV_XS;
use HTGT::DBFactory;
use Data::Dumper;
use Readonly;

Readonly my $EDIT_USER => $ENV{USER};

Readonly my %IS_PROMOTORLESS_CASSETTE =>  map { $_ => 1 }
    qw( L1L2_gt0 L1L2_gt1 L1L2_gt2 L1L2_gtk L1L2_st0 L1L2_st1 L1L2_st2 );

Readonly my $MIN_PROMOTORLESS_TRAPS => 4;

my $exit_code = 0;

{
    
    my $log_level = $WARN;

    GetOptions(
        help    => sub { pod2usage( -verbose => 1 ) },
        man     => sub { pod2usage( -verbose => 2 ) },
        debug   => sub { $log_level = $DEBUG },
        verbose => sub { $log_level = $INFO },
        commit  => \my $commit,
    ) or pod2usage(2);
    
    Log::Log4perl->easy_init( level => $log_level, layout => '%m%n' );

    my $htgt = HTGT::DBFactory->connect( 'eucomm_vector', { AutoCommit => 1 } );
    INFO( "Connected to database " . $htgt->storage->dbh->{Name} );

    my $recovery_data = parse_recovery_data( @ARGV );

    $htgt->txn_do( \&update_gene_recovery, $htgt, $commit, $recovery_data );

    exit $exit_code;
}

sub update_gene_recovery {
    my ( $htgt, $commit, $recovery_data_for_marker ) = @_;
    
    while ( my ( $marker_symbol, $data_for_marker ) = each %{ $recovery_data_for_marker } ) {
        my $gene_rs = find_gene_by_marker( $htgt, $marker_symbol )
            or next;

        my $recovery_data = build_recovery_data( $data_for_marker );
        DEBUG( sub { Dumper( $recovery_data ) } );
        
        my ( $candidate_for, $candidate_evidence );
        if ( $recovery_data->{has_alternates} ) {
            $candidate_for      = 'acr';
            $candidate_evidence = join( '|', @{$recovery_data}{ qw( chosen alternates sp tm trap_count epd_count ) } ); 
        }
        elsif ( suitable_for_gateway( $recovery_data ) ) {
            $candidate_for      = 'gwr';
            $candidate_evidence = join( '|', @{$recovery_data}{ qw( chosen sp tm trap_count epd_count ) } );
        }
        else {
            # No alternates with promoter, not suitable for promotorless recovery
            next;
        }

        create_or_update_gene_recovery( $gene_rs, $candidate_for, $candidate_evidence );
    }

    die "Rollback\n" unless $commit;
}

sub suitable_for_gateway {
    my $rd = shift;

    return 1
        if ( $rd->{sp} or $rd->{tm} or $rd->{trap_count} < $MIN_PROMOTORLESS_TRAPS )
            and not $rd->{has_promoter};

    return 0; 
}

sub parse_recovery_data {
    
    my $csv = Text::CSV_XS->new();

    my %recovery_data_for_marker;
    
    for ( @_ ) {
        DEBUG( "Reading alternate clone recovery data from $_" );
        my $ifh = IO::File->new( $_, O_RDONLY )
            or die "open $_: $!";
        $csv->parse( $ifh->getline )
            or die "parse error: " . $csv->error_diag;
        $csv->column_names( $csv->fields );
        while ( my $d = $csv->getline_hr( $ifh ) ) {
            push @{ $recovery_data_for_marker{ $d->{marker_symbol} } }, $d;
        }
    }

    return \%recovery_data_for_marker;
}

sub build_recovery_data {
    my $raw_data = shift;
    
    my ( @chosen, @alternates, $has_promoter );
    for my $rd ( @{ $raw_data } ) {
        push @chosen, split " ", $rd->{chosen_clones};
        if ( $rd->{pgdgr_plate} ) {
            push @alternates, sprintf( '%s[%s]', @{$rd}{qw(pgdgr_plate pgdgr_well)} );
        }
        $has_promoter++ unless $IS_PROMOTORLESS_CASSETTE{ $rd->{cassette} };
    }

    return {
        chosen         => join( q{,}, uniq sort @chosen ),
        alternates     => join( q{,}, uniq sort @alternates ),
        has_alternates => scalar( @alternates ),
        has_promoter   => $has_promoter || 0,
        sp             => $raw_data->[0]->{sp} || 0,
        tm             => $raw_data->[0]->{tm} || 0,
        trap_count     => $raw_data->[0]->{targeted_trap} || 0,
        epd_count      => $raw_data->[0]->{epd_distribute_count} || 0,
    };
}

sub create_or_update_gene_recovery {
    my ( $gene_rs, $candidate_for, $candidate_evidence ) = @_;
       
    my $evidence_field = "${candidate_for}_candidate_evidence";

    my $gene = $gene_rs->first;
    
    if ( my $gene_recovery = $gene->gene_recovery ) {
        my $old_candidate_evidence = $gene_recovery->$evidence_field || '<undef>';
        if ( $candidate_evidence ne $old_candidate_evidence ) {
            INFO( "Update " . $gene->mgi_accession_id . " $evidence_field: $old_candidate_evidence => $candidate_evidence" );            
            $gene_recovery->update( {
                $evidence_field => $candidate_evidence,
                edit_date       => \'current_timestamp',
                edit_user       => $EDIT_USER
            } );
        }   
    }
    else {
        INFO( "Insert " . $gene->mgi_accession_id . " $evidence_field: $candidate_evidence" );
        $gene_rs->create( {
            gene_recovery => {
                $evidence_field => $candidate_evidence,
                edit_date       => \'current_timestamp',
                edit_user       => $EDIT_USER
            }
        } );
    }
}

sub find_gene_by_marker {
    my ( $htgt, $marker_symbol ) = @_;
    
    my $gene_rs = $htgt->resultset( 'MGIGene' )->search( { marker_symbol => $marker_symbol } );
    my $count = $gene_rs->count;

    if ( $count == 0 ) {
        $exit_code = 1;
        ERROR( "No MGIGene record found for marker_symbol $marker_symbol" );
        return;
    }
    if ( $count > 1 ) {
        $exit_code = 1;
        ERROR( "Multiple MGIGene records found for marker_symbol $marker_symbol" );
        return;
    }

    return $gene_rs;
}

__END__

=head1 NAME

update_gene_recovery_acr.pl - Describe the usage of script briefly

=head1 SYNOPSIS

update_gene_recovery_acr.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for update_gene_recovery_acr.pl, 

=head1 AUTHOR

Ray Miller, E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Genome Research Ltd

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
