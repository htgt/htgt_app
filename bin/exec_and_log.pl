#!/usr/bin/env perl
# exec_and_log.pl --- Execute a command, logging its output to a file
# Author: Ray Miller <rm7@sanger.ac.uk>
# Created: 28 Jan 2010
# 

use Getopt::Long ();
use HTGT::Utils::ExecAndLog;

Getopt::Long::Configure( 'pass_through', 'require_order' );

my $app = HTGT::Utils::ExecAndLog->new_with_options;

my $rc = $app->run( @{ $app->extra_argv } );

exit $rc;

__END__

=head1 NAME

exec_and_log.pl - run a command, logging its output to a file

=head1 SYNOPSIS

  exec_and_log.pl --logfile=PATH --tag=TAG -- CMD [ARGS ...]

=head1 DESCRIPTION

This script will run a command, capturing STDOUT and STDERR and
logging to the specified file.  If the command exits non-zero, the
output is also dumped to STDERR. The

=head1 OPTIONS

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
