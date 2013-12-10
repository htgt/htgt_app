package Catalyst::Authentication::Store::LIMS2Store;

use strict;
use warnings FATAL => 'all';

use HTGT::Authen::LIMS2User;

use base 'Catalyst::Authentication::Store';

sub get_user{
	my ($self, $id) = @_;
	
	my $user = HTGT::Authen::LIMS2User->new(
	    username => $id,
	    id       => $id,
	);
	
	return $user;
}

sub from_session {
	my ($self, $c, $id) = @_;

	return $id if ref $id;
    return $self->find_user({ id => $id });
}

1;