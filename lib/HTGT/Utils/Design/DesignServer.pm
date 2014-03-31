package HTGT::Utils::Design::DesignServer;

use strict;
use warnings;

use Path::Class;
use Time::HiRes;

=head1 NAME

Utility methods that USED to be on the old design-server standalone instance

=cut

=head2 index

=cut

sub new
{
  my $self = {};
  bless $self;
  return $self;
}

sub design_only {
    my ( $self, $c, $design_id )    = @_;

    my $dirname = sprintf( 'd_%d.%d.%d.%d', $design_id, $$, Time::HiRes::gettimeofday() );
    my $design_home = dir( $c->config->{design_home} )->subdir( $dirname );
    
    mkdir($design_home, 0775) or die "Could not create design directory $design_home - $!";

    # create_design.pl command is piped to ssh command so that it is executed
    # after the exec of the htgt-env.pl script to create the environment
    my @run_design_command = ( "echo \"create_design.pl -design_home $design_home -design_id $design_id"
                               ,"1> $design_home/bjob_output 2> $design_home/bjob_error &\"",
                               '|',
                               'ssh',
                               'htgt-web',
                               'exec',
                               '/software/bin/perl',
                               '-I/software/team87/brave_new_world/lib/perl5',
                               '-I/software/team87/brave_new_world/lib/perl5/x86_64-linux-thread-multi',
                               '/software/team87/brave_new_world/bin/htgt-env.pl',
                               '--environment',
                               $ENV{HTGT_ENV}                            
                           );

    my $command = join " ", @run_design_command;
    $c->log->info( "submiting ssh command: ". $command );

    system( $command ) == 0
        or $c->log->error( "Failed to run command: $! (exit $?)" );
}

=head1 AUTHOR

Vivek Iyer

Wanjuan Yang

=cut

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
