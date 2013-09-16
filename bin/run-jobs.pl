#!/usr/bin/env perl
# run-jobs.pl --- An implementation of run-parts with logging
# Author: Ray Miller <rm7@hpgen-1-14.internal.sanger.ac.uk>
# Created: 01 Feb 2010
# Version: 0.01

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use File::Basename 'basename';
use File::Find::Rule;
use HTGT::Utils::ExecAndLog;
use Pod::Usage;

GetOptions(
    'help'               => sub { pod2usage( -verbose => 1 ) },
    'man'                => sub { pod2usage( -verbose => 2 ) },
    'logfile=s'          => \my $logfile,
    'continue-on-error!' => \my $continue,
    'list'               => \my $list,
) or pod2usage( 2 );

my $jobdir = shift @ARGV
    or pod2usage( "JOBDIR not specified" );

my $tag_base = basename( $jobdir );

# XXX check that $jobdir exists?

my @files = sort { $a->{basename} cmp $b->{basename} }
    map {
        { basename => basename( $_ ), path => $_ }
    }
    File::Find::Rule->file()->executable()->name( qr/^[\w-]+$/ )->maxdepth( 1 )->in( $jobdir );

if ( $list ) {
    print "$_->{basename}\n" for @files;
    exit 0;
}

my $final_rc = 0;

for my $f ( @files ) {
    my $tag = "$tag_base.$f->{basename}";
    my $exec = HTGT::Utils::ExecAndLog->new( { logfile => $logfile, tag => $tag } );
    my $rc = $exec->run( $f->{path} );
    $final_rc ||= $rc;
    last if $rc and not $continue;
}

exit $final_rc;

__END__

=head1 NAME

run-jobs.pl - an implementation of run-parts with logging

=head1 SYNOPSIS

run-jobs.pl [options] JOBDIR

      --help
      --man
      --logfile=LOGFILE
      --continue-on-error
      --list

=head1 DESCRIPTION

This is an implementation of B<run-parts> with logging support. It
will search for executable scripts in I<JOBDIR> whose names consist
entirely of upper- and lower-case letters, digits, dashes, or
underscores, and run each script in collating sequence order. The
standard output and standard error is tagged and written to to
I<LOGFILE>.

If any script exits non-zero, the script's standard output and
standard error will be also written to the standard error stream. No
further scripts in I<JOBDIR> will be executed unless
B<--continue-on-error> is specified.

=head1 OPTIONS

=over 4

=item B<--help>

Display a brief help message.

=item B<--man>

Display the manual page.

=item B<--logfile>

Specify the path of the log file.

=item B<--continue-on-error>

Continue if a script exits non-zero (default is to stop immediately on
error).

=item B<--list>

List the jobs that would be run and exit immediately.

=back

=head1 SEE ALSO

L<run-parts(8)>.

=head1 AUTHOR

Ray Miller, E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Ray Miller

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
