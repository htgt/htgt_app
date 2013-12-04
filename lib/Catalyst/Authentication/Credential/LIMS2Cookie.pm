package Catalyst::Authentication::Credential::LIMS2Cookie;
#
# $HeadURL$
# $LastChangedDate$
# $LastChangedRevision$
# $LastChangedBy$
#

use strict;
use warnings FATAL => 'all';

use base 'Class::Accessor::Fast';

BEGIN {
    __PACKAGE__->mk_ro_accessors( qw( username_field ) );
}

=head2 new

Construct a Catalyst::Authentication::Credential::LIMS2Cookie object.

=cut

sub new {
    my ( $class, $config, $app, $realm ) = @_;
    my %self = ( username_field => $config->{username_field} || 'username' );
    bless( \%self, $class );
}

=head2 authenticate

Retrieve the authenticated username from B<SangerWeb> and look up a
corresponding user via B<find_user>; returns the user object.

=cut

sub authenticate {
     my ( $self, $c, $realm, $authinfo ) = @_;
     
     $c->log->debug("Looking for LIMS2Auth cookie");
     
     my $cookie = $c->request->cookie('LIMS2Auth');
     my $auth_user;
     
     if ($cookie and my $user = $cookie->{value}){
     	($auth_user) = @$user;
     }
     else{
     	$c->log->debug( "User not authenticated: no LIMS2 authorisation cookie found");
     	return;
     }
     
     unless ( $auth_user ) {
         $c->log->debug( "User not authenticated: no username in LIMS2 authorisation cookie" );
         return;
     }
          
     my $user_obj = $realm->find_user( { $self->username_field => $auth_user, id => $auth_user }, $c );
     unless ( $user_obj ) {
         $c->log->error( "User '$auth_user' not found in htgt users" );
         return;
     }
     
     return $user_obj;

}

1;