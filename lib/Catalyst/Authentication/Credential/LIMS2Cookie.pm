package Catalyst::Authentication::Credential::LIMS2Cookie;
#
# $HeadURL$
# $LastChangedDate$
# $LastChangedRevision$
# $LastChangedBy$
#

use strict;
use warnings FATAL => 'all';

use Crypt::CBC;
use Config::Simple;

use base 'Class::Accessor::Fast';

BEGIN {
    __PACKAGE__->mk_ro_accessors( qw( username_field default_roles) );
}

=head2 new

Construct a Catalyst::Authentication::Credential::LIMS2Cookie object.

=cut

sub new {
    my ( $class, $config, $app, $realm ) = @_;
    my %self = ( 
        username_field => $config->{username_field} || 'username',
        default_roles  => [ qw( read edit eucomm eucomm_edit) ],
    );
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
     
     my $cookie_data;
     ($cookie_data) = @{ $cookie->{value} || [] };
     if ($cookie and $cookie_data){
     	$c->log->debug("Encrypted cookie value: $cookie_data");
        
        my $conf_file = $ENV{LIMS2_REST_CLIENT_CONF} 
            or die "Cannot complete LIMS2 login - no LIMS2_REST_CLIENT_CONF environment variable set.";
    
        my $conf = new Config::Simple($conf_file);
        my $key = $conf->param("auth_key")
            or die "Cannot complete LIMS2 login - no auth_key provided in $conf_file ";          
        my $cipher = Crypt::CBC->new( -key => $key, -cipher => 'Blowfish' );

        my $text = $cipher->decrypt($cookie_data);
        $c->log->debug("Decrypted cookie value: $text");
        
     	my $sessionid;
     	($sessionid,$auth_user) = split ":", $text;
     	
     	# Check we have the correct session id for authentication
     	unless ($sessionid eq $c->sessionid){
     		$c->log->debug( "Session ID in authentication cookie does not match current session" );
     		return;
     	}
     }
     else{
     	$c->log->debug( "User not authenticated: no LIMS2 authorisation cookie found");
     	return;
     }
     
     unless ( $auth_user ) {
         $c->log->debug( "User not authenticated: no username in LIMS2 authorisation cookie" );
         return;
     }
          
     my $user_obj = $realm->find_user(
         { $self->username_field => $auth_user, id => $auth_user, },
         $c 
     );
     
     unless ( $user_obj ) {
         $c->log->error( "User '$auth_user' not found in htgt users" );
         return;
     }
     
     $user_obj->roles($self->default_roles);     
     
     return $user_obj;

}

1;