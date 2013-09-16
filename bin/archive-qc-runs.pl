#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Archive::Tar;
use DateTime;
use DateTime::Duration;
use Time::Duration::Parse;
use File::Find::Rule;
use Getopt::Long;
use Pod::Usage;
use Readonly;

Readonly my $MATCH_OUT_ERR      => qr/^[^.]+\.[^.]+.(\d+)-(\d+)-(\d+)T.*\.(?:out|err)$/;
Readonly my $MATCH_CLONES_TESTS => qr/^plate.+__all(?:clones|tests)\.csv$/;

my $qc_runs_dir = '/nfs/users/nfs_t/team87/qc_runs';
my $archive_dir = '/nfs/users/nfs_t/team87/qc_runs_archive';
my $max_age     = '1 month';

GetOptions(
    help  => sub { pod2usage( -verbose => 1 ) },
    man   => sub { pod2usage( -verbose => 2 ) },
    'qc-runs-dir=s'  => \$qc_runs_dir,
    'archive-dir=s'  => \$archive_dir,
    'max-age=s'      => \$max_age,
    'verbose'        => \my $verbose,
    'delete'         => \my $delete,
) or pod2usage(2);

my $age_seconds = parse_duration( $max_age )
    or die "Invalid age: $max_age\n";

my $cutoff = DateTime->now - DateTime::Duration->new( seconds => $age_seconds );

my @to_archive = File::Find::Rule->file->maxdepth(1)->exec( \&want_archive )->in( $qc_runs_dir );
if ( $verbose ) {
    warn "Archive $_\n" for @to_archive;
}

if(scalar(@to_archive) == 0) {
    printf "Nothing to archive!\n";
    exit 0;
}

my $archive_file = File::Spec->catfile( $archive_dir, DateTime->now->ymd . '.tgz' );
Archive::Tar->create_archive( $archive_file, COMPRESS_GZIP, @to_archive )
    or die Archive::Tar->error;

if ( $delete ) {
    for ( @to_archive, File::Find::Rule->file->name( $MATCH_CLONES_TESTS )->maxdepth(1)->in( $qc_runs_dir ) ) {
        warn "Delete $_\n" if $verbose;
        unlink $_ or die "unlink $_: $!";
    }
}

sub want_archive {
    my $filename = shift;

    my ( $y, $m, $d ) = $filename =~ $MATCH_OUT_ERR
        or return;

    DateTime->new( year => $y, month => $m, day => $d ) < $cutoff;
}

__END__

=pod

=head1 NAME

archive-qc-runs

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>

=cut
