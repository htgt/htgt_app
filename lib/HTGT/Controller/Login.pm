package HTGT::Controller::Login;
use Moose;
use namespace::autoclean;

use Config::Simple;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

HTGT::Controller::Login - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut
use Data::Dumper;
sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $conf_file = $ENV{LIMS2_REST_CLIENT_CONF} 
        or die "Cannot proceed to LIMS2 login - no LIMS2_REST_CLIENT_CONF environment variable set.";
    
    my $conf = new Config::Simple($conf_file);
    $c->log->debug(Dumper($conf));
    my $url = $conf->param("login_url")
        or die "Cannot proceed to LIMS2 login - no login_url provided in $conf_file ";
    
    my $sessionid = $c->sessionid;
    
    # Store the lims2 change password link for use later
    $c->session->{change_password_url} = $conf->param("change_password_url");
    
    $c->res->redirect($url."?htgtsession=".$sessionid."&goto_on_success=".$c->uri_for('/welcome'));
    return;
}


=head1 AUTHOR

Anna Farne

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
