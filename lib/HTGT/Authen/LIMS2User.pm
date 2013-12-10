package HTGT::Authen::LIMS2User;

use strict;
use warnings FATAL => 'all';
use Set::Object;

use base 'Catalyst::Authentication::User';

BEGIN {
    __PACKAGE__->mk_ro_accessors( qw( username id ) );
    __PACKAGE__->mk_accessors( qw( roles ) );
}

my %features = ( session => 1, roles => {self_check => 1} );

sub supported_features {
   my $self = shift;
   return \%features;
}

sub check_roles{
	my ($self, @roles) = @_;
    
    my $have = Set::Object->new(@{ $self->roles || [] });
    my $need = Set::Object->new(@roles);

    if ( $have->superset($need) ) {
        return 1;
    }
    else {
        return 0;
    }
    
    return;
}

sub for_session {
    my $self = shift;
    return $self;
}

sub from_session {
    my ($self, $c, $user) = @_;
    return $user;
}
1;