#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/cleanup-design-workdir.pl $
# $LastChangedRevision: 4485 $
# $LastChangedDate: 2011-03-25 11:35:04 +0000 (Fri, 25 Mar 2011) $
# $LastChangedBy: rm7 $

use strict;
use warnings FATAL => 'all';

use Pod::Usage;
use Path::Class;
use Getopt::Long;
use Time::Duration::Parse;
use Const::Fast;

const my $DESIGN_WORKDIR_RX => qr/d_\d+\.\d+\.\d+\.\d+$/;

my $workdir   = dir( '/lustre/scratch103/sanger/team87/designs' );
my $threshold = parse_duration( '7 days' );
my $dryrun    = 0;
my $verbose   = 0;

GetOptions(
    'help'        => sub { pod2usage( -verbose => 1 ) },
    'man'         => sub { pod2usage( -verbose => 2 ) },
    'workdir=s'   => sub { $workdir = dir( $_[1] ) },
    'threshold=s' => sub { $threshold = parse_duration( $_[1] ) },
    'dry-run'     => \$dryrun,
    'verbose'     => \$verbose,
) or pod2usage(2);

my $cutoff = time() - $threshold;

my $handle = $workdir->open()
    or die "open $workdir: $!\n";

while ( my $dirent = $handle->read ) {    
    $dirent =~ m/$DESIGN_WORKDIR_RX/
        or next;
    my $dir = $workdir->subdir( $dirent );
    my $st = $dir->stat
        or next;
    $st->mtime < $cutoff
        or next;
    if ( $dryrun ) {
        print "Delete $dir\n";
    }
    else {
        $dir->rmtree( $verbose );        
    }
}

__END__

=head1 NAME

cleanup-design-workdir

=head1 SYNOPSIS

  cleanup-design-workdir [OPTIONS]

  Options:

    --help                Display a brief help message
    --man                 Display the manual page
    --workdir=PATH        Specify the path of the EUCOMM::Designer working directory
                          (default /lustre/scratch103/sanger/team87/designs)
    --threshold=DURATION  Directories older than DURATION will be deleted (default 7 days)
    --dry-run             Show what would be done without deleting any directories
    --verbose             Be more verbose

=head1 DESCRIPTION

Delete old EUCOMM::Designer working directories.

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>

=cut




