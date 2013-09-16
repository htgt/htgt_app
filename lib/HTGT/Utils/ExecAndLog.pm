package HTGT::Utils::ExecAndLog;

use Moose;
use namespace::autoclean;

use DateTime;
use File::Temp ':seekable';
use IO::Pipe;
use IO::Select;
use Log::Dispatch;
use Log::Dispatch::File;

with 'MooseX::Getopt';

has logfile => (
    traits   => [ 'Getopt' ],
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has tag => (
    traits   => [ 'Getopt' ],
    is       => 'ro',
    isa      => 'Str',
);

has tmpfile => (
    traits   => [ 'NoGetopt' ],
    is       => 'ro',
    isa      => 'File::Temp',
    required => 1,
    default  => sub { File::Temp->new }
);

has dispatcher => (
    traits  => [ 'NoGetopt' ],
    is      => 'rw',
    isa     => 'Log::Dispatch',
);

sub BUILD {
    my $self = shift;

    my $dispatcher = Log::Dispatch->new;

    $dispatcher->add( Log::Dispatch::File->new( name      => 'logfile',
                                                min_level => 'debug',
                                                filename  => $self->logfile,
                                                mode      => 'append'
                                            )
    );

    $dispatcher->add( Log::Dispatch::File->new( name      => 'tmpfile',
                                                min_level => 'debug',
                                                filename  => $self->tmpfile->filename,
                                                mode      => 'write'
                                            )
    );

    $self->dispatcher( $dispatcher );
}

sub log {
    my ( $self, $category, $mesg ) = @_;
    chomp( $mesg );
    my $datetime = DateTime->now->iso8601;
    if ( defined( my $tag = $self->tag ) ) {
        $self->dispatcher->notice( "$datetime [$tag] ($category) $mesg\n" );
    }
    else {
        $self->dispatcher->notice( "$datetime ($category) $mesg\n" );
    }
}

sub dump_tmp_file {
    my $self = shift;

    my $tmp = $self->tmpfile;
    $tmp->seek( 0, 0);

    while ( my $line = $tmp->getline ) {
        print STDERR $line;
    }
}

sub run_cmd {
    my ( $self, $cmd, $out, $err ) = @_;

    defined( my $pid = fork() )
        or confess "fork failed: $!";
    
    if ( $pid == 0 ) { # child
        $out->writer;
        $err->writer;
        open( STDOUT, '>&' . $out->fileno )
            or confess "dup STDOUT: $!";
        open( STDERR, '>&' . $err->fileno )
            or confess "dup STDERR: $!";
        open( STDIN, '</dev/null' )
            or confess "dup STDIN: $!";
        exec( @{ $cmd } )
            or confess "exec @{ $cmd }: $!";
    }

    return $pid;
}

sub reap_child {
    my ( $self, $pid ) = @_;

    waitpid( $pid, 0 ) > 0
        or confess "failed to reap child $pid";
    
    my $rc = $? >> 8;
    my $mesg = "Child exited $rc";
    if ( my $signal = $? & 128 ) {
        $mesg .= " (killed by signal $signal)";
    }
    $self->log( '', $mesg );

    return $rc;
}

sub run {
    my ( $self, @cmd ) = @_;

    confess "Command not specified"
        unless @cmd;
    
    my $err = IO::Pipe->new;
    my $out = IO::Pipe->new;

    my $child = $self->run_cmd( \@cmd, $out, $err );

    my $select = IO::Select->new;
    for ( $err, $out ) {
        $_->reader;
        $select->add( $_ );
    }

    while ( my @ready = $select->can_read ) {
        for my $fh ( @ready  ) {
            my $category = $fh == $err ? 'STDERR' : 'STDOUT';
            if ( defined( my $line = $fh->getline ) ) {
                $self->log( $category, $line );
            }
            else {
                # EOF
                $select->remove( $fh );   
            }
        }
    }

    my $rc = $self->reap_child( $child );
        
    if ( $rc ) {
        $self->dump_tmp_file;
    }

    return $rc;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTGT::Utils::ExecAndLog - execute a command and log its output

=head1 SYNOPSIS

   use HTGT::Utils::ExecAndLog;
   my $app = HTGT::Utils::ExecAndLog->new_with_options;
   my $rc = $app->run( @{ $app->extra_argv } );

   use HTGT::Utils::ExecAndLog;
   HTGT::Utils::ExecAndLog->new( { logfile => '/var/log/foo.log' } )->run( '/bin/echo', 'hello' );

=head1 DESCRIPTION

This module provides a wrapper to fork and execute a child process,
capturing its output and logging to a file.

=head1 METHODS

=head2 C<new_with_options>

Create object, taking arguments from command-line

=head2 C<new>

Create object, taking arguments from hash

=head2 C<run>

Run the specifed command

=head1 SEE ALSO

L<MooseX::Getopt>, L<Log::Dispatch>, L<IO::File>

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
