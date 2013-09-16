#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/notify_regeneron_status_change.pl $
# $LastChangedRevision: 4780 $
# $LastChangedDate: 2011-04-18 15:13:04 +0100 (Mon, 18 Apr 2011) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory;
use HTGT::BioMart::QueryFactory;
use File::Temp;
use IO::Handle;
use IO::File;
use Text::CSV_XS;
use Mail::Address;
use MIME::Lite;

my @recipients;

GetOptions(
    'help'       => sub { pod2usage( -verbose => 1 ) },
    'man'        => sub { pod2usage( -verbose => 2 ) },
    'commit'     => \my $commit,
    'notify=s@'  => sub { push @recipients, map $_->format, Mail::Address->parse( $_[1] ) },
) or pod2usage(2);


my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

my $changes = eval {
    $htgt->txn_do( \&update_cached_status )
};
if ( my $err = $@ ) {
    eval { $htgt->txn_rollback };
    die $err;
}

if ( @{ $changes } ) {
    notify( $changes, \@recipients );
}

sub update_cached_status {

    my @changes;
    
    my $qf = HTGT::BioMart::QueryFactory->new( martservice => 'http://www.i-dcc.org/biomart/martservice' );

    my $query = $qf->query(
        {
            dataset    => 'dcc',
            filter     => { project => 'KOMP-Regeneron' },
            attributes => [ qw( mgi_accession_id regeneron_current_status ) ], 
        }
    );

    for ( @{ $query->results } ) {
        my $mgi_accession_id = $_->{mgi_accession_id};
        my $current_status   = $_->{regeneron_current_status};
        my $mgi_gene = $htgt->resultset( 'MGIGene' )->search( { mgi_accession_id => $mgi_accession_id } )->first;
        unless ( $mgi_gene ) {
            warn "$mgi_accession_id not found\n";
            next;
        }
        my $cached = $htgt->resultset( 'CachedRegeneronStatus' )->find_or_create(
            {
                mgi_accession_id => $mgi_accession_id
            }
        );
        my $cached_status = $cached->status || '(none)';
        unless ( $cached_status eq $current_status ) {
            push @changes, [
                $mgi_gene->marker_symbol, $mgi_accession_id, $cached_status, $cached->last_updated, $current_status,
                #$mgi_gene->marker_symbol, $mgi_accession_id, $cached_status, undef, $current_status,
                latest_targvec_well( $mgi_gene )
            ];
            $cached->update( {
                status       => $current_status,
                last_updated => \'current_timestamp'
            } );
        }        
    }

    unless ( $commit ) {
        warn "Rollback requested\n";
        $htgt->txn_rollback;        
    }

    return \@changes;
}

sub latest_targvec_well {
    my ( $mgi_gene ) = @_;

    my @targvec_wells = map $_->[0],
        sort { $b->[1] <=> $a->[1] }
            map [ $_, $_->plate->created_date ],
                grep defined, 
                    map $_->pgdgr_well,
                        map $_->ws_by_di_entries, $mgi_gene->projects;
    
    shift @targvec_wells;
}

sub notify {
    my ( $changes, $recipients ) = @_;

    if ( @{ $recipients } ) {
        my $tempdir = File::Temp->newdir();
        my $csv_file = File::Spec->catfile( $tempdir, 'status_changes.csv' );
        my $ofh = IO::File->new( $csv_file, O_CREAT|O_EXCL|O_RDWR, 0644 )
            or die "create $csv_file: $!";
        write_changes( $changes, $ofh );
        send_file( $csv_file, $recipients );
    }
    else {
        my $ofh = IO::Handle->new->fdopen( fileno(STDOUT), 'w' )
            or die "dup STDOUT: $!";
        write_changes( $changes, $ofh );
    }
}

sub write_changes {
    my ( $changes, $ofh ) = @_;

    my $csv = Text::CSV_XS->new( { eol => $/ } );

    $csv->print( $ofh, [ 'Marker Symbol', 'MGI Accession Id', 'Previous Status', 'Previous Status Update', 'New Status' ] );
    $csv->print( $ofh, $_ ) for @{ $changes };

    $ofh->close;
}

sub send_file {
    my ( $filename, $recipients ) = @_;

    my $msg = MIME::Lite->new(
        From     => 'vecinfor@sanger.ac.uk',
        To       => join( q{,}, @{ $recipients } ),
        Subject  => 'KOMP/Regeneron Status Changes',
        Type     => 'multipart/mixed',
    );
    $msg->attach(
        Type        => 'TEXT',
        Data        => 'KOMP/Regeneron status changes for ' . localtime() . ' attached.',
        Disposition => 'inline',
            
    );
    $msg->attach(
        Type        => 'text/csv',
        Path        => $filename,
        Disposition => 'attachment',
    );
    $msg->send;
}

__END__

=head1 NAME

notify_regeneron_status_change.pl - notify changes in KOMP/Regeneron status

=head1 SYNOPSIS

notify_regeneron_status_change.pl [OPTIONS]

      --help    Display a brief usage message
      --man     Display the manual page
      --commit  Commit changes to the database (default is to rollback)
      --notify  Email address for notifications; may be specified more than once
                (default is to write changes to STDOUT)

=head1 DESCRIPTION

This program retrieves the latest KOMP/Regeneron status for a gene
from the IDCC biomart and compares the current value with the value
cached in the HTGT database. The cached value is updated and any
status changes are written to a CSV file and (optionally) sent by
email to the recipients given by B<--notify>. If no recipients are
listed, the CSV is written to STDOUT.

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
