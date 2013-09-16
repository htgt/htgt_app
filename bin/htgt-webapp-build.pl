#!/usr/bin/env perl
# htgt-build.pl --- build HTGT Catalyst package from svn export
# Author: Ray Miller <rm7@hpgen-1-14.internal.sanger.ac.uk>
# 
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/htgt-webapp-build.pl $
# $LastChangedRevision: 1988 $
# $LastChangedDate: 2010-06-24 10:28:09 +0100 (Thu, 24 Jun 2010) $
# $LastChangedBy: rm7 $

use warnings FATAL => 'all';
use strict;
use sigtrap die => 'normal-signals';

use Date::Format 'time2str';
use File::Basename 'dirname';
use File::Find::Rule;
use File::Path 'remove_tree';
use File::Spec;
use File::Temp;
use Getopt::Long;
use IO::File;
use Pod::Usage;
use Readonly;
use Term::Query 'query';

Readonly my $DEFAULT_SVN_URL  => 'svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt/';
Readonly my $DEFAULT_DEST_DIR => '/software/team87/brave_new_world/src/perl-modules';

sub init {    

    GetOptions(
        help    => sub { pod2usage( -verbose => 1 ) },
        man     => sub { pod2usage( -verbose => 2 ) },
        branch  => \my $branch,
        tag     => \my $tag,
        url     => \my $svn_url,
        destdir => \my $dest_dir,
    ) or pod2usage( 2 );

    $svn_url  ||= $DEFAULT_SVN_URL;
    $dest_dir ||= $DEFAULT_DEST_DIR;

    if ( $branch ) {
        $svn_url .= "branches/$branch";
    }
    elsif ( $tag ) {
        $svn_url .= "tags/$tag";
    }
    else {
        $svn_url .= "trunk";
    }

    return ( $svn_url, $dest_dir );
}

sub svn_export {
    my $svn_url = shift;
    
    my $work_dir = File::Temp->newdir( CLEANUP => 0 )
        or die "create tmpdir: $!";
    
    my $build_dir = File::Spec->catdir( $work_dir, 'build' );

    system( qw( svn export ), $svn_url, $build_dir ) == 0
        or die "svn export failed";

    return $build_dir;
}

sub stamp_version_on_file {
    my ( $file, $version ) = @_;

    my $ifh = IO::File->new( $file, O_RDONLY )
        or die "open $file: $!";

    my $ofh = IO::File->new( "$file.new", O_RDWR|O_EXCL|O_CREAT, 0644 )
        or die "create $file.new: $!";

    while ( <$ifh> ) {
        $ofh->print( $_ );
        if ( /^\s*package\s/ ) {
            $ofh->print( "\nour \$VERSION = $version;\n\n" );
        }
    }

    $ofh->close
        or die "close $file.new: $!";

    $ifh->close
        or die "close $file: $!";

    rename "$file.new", $file
        or die "rename $file.new to $file: $!";
}

sub stamp_version {
    my $build_dir = shift;

    my $lib_dir = File::Spec->catdir( $build_dir, 'lib' );
    my $htgt_version = time2str( '1.%y%j%H%M', time );

    for my $file ( File::Find::Rule->file()->name( '*.pm' )->in( $lib_dir ) ) {
        stamp_version_on_file( $file, $htgt_version );
    }
    
    return $htgt_version;
}

sub build_tardist {
    my $build_dir = shift;

    chdir $build_dir
        or die "chdir $build_dir: $!";

    system( 'perl', 'Makefile.PL' ) == 0
        or die "perl Makefile.PL failed";
    
    system( 'make', 'manifest', 'tardist' ) == 0
        or die "build failed";
}

sub copy_tarball {
    my ( $build_dir, $version, $dest_dir ) = @_;

    my $tarball = File::Spec->catfile( $build_dir, "HTGT-" . $version . '.tar.gz' );

    system( 'cp', $tarball, $dest_dir ) == 0
        or die "cp tarball failed";
}

sub cleanup_build_dir {
    my $build_dir = shift;

    chdir( '/' );
    remove_tree( dirname( $build_dir ), { verbose => 1 } );
}

my ( $svn_url, $dest_dir ) = init();

my $build_dir = svn_export( $svn_url );

END {
    if ( query( 'Preserve build directory?', 'N' ) eq 'yes' ) {
        print "Output kept in $build_dir\n";
    }
    else {
        cleanup_build_dir( $build_dir );
    }
}

my $version = stamp_version( $build_dir );

build_tardist( $build_dir );

if ( query( 'Copy tarball to CPAN custom source dir?', 'Y' ) eq 'yes' ) {
    copy_tarball( $build_dir, $version, $dest_dir );
}

__END__

=head1 NAME

htgt-build.pl - Describe the usage of script briefly

=head1 SYNOPSIS

htgt-build.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for htgt-build.pl, 

=head1 AUTHOR

Ray Miller, E<lt>rm7@hpgen-1-14.internal.sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Ray Miller

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
