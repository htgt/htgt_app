package HTGT::Utils::Tarmits;

use strict;
use warnings FATAL => 'all';

use Moose;
use Moose::Util::TypeConstraints;
use LWP::UserAgent;
use namespace::autoclean;
use JSON;
use Readonly;
require URI;
use Carp::Assert;

with qw( MooseX::SimpleConfig MooseX::Log::Log4perl );

subtype 'HTGT::Utils::Tarmits::URI' => as class_type('URI');

coerce 'HTGT::Utils::Tarmits::URI' => from 'Str' => via { URI->new($_) };

has '+configfile' => ( default => $ENV{TARMITS_CLIENT_CONF} );

has 'base_url' => (
    is       => 'ro',
    isa      => 'HTGT::Utils::Tarmits::URI',
    coerce   => 1,
    required => 1
);

has 'proxy_url' => (
    is     => 'ro',
    isa    => 'HTGT::Utils::Tarmits::URI',
    coerce => 1
);

has [qw(username password)] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'realm' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'iMits'
);

has 'ua' => (
    is         => 'ro',
    isa        => 'LWP::UserAgent',
    lazy_build => 1
);

sub _build_ua {
    my $self = shift;

    # Set proxy
    my $ua = LWP::UserAgent->new();
    $ua->proxy( http => $self->proxy_url )
        if defined $self->proxy_url;

    # Set credentials
    if ( $self->username ) {
        $ua->credentials( $self->base_url->host_port, $self->realm, $self->username, $self->password );
    }

    return $ua;
}

#
#   Private methods
#
sub uri_for {
    my ( $self, $path, $params ) = @_;

    my $uri = URI->new_abs( $path, $self->base_url );
    if ($params) {
        $uri->query_form($params);
    }

    return $uri;
}

sub request {
    my ( $self, $method, $rel_url, $data ) = @_;

    my ( $uri, $request );

    if ( $method eq 'GET' or $method eq 'DELETE' ) {
        $uri = $self->uri_for( $rel_url, $data );
        $request = HTTP::Request->new( $method, $uri, [ content_type => 'application/json' ] );
    }
    elsif ( $method eq 'PUT' or $method eq 'POST' ) {
        $uri = $self->uri_for($rel_url);
        $request = HTTP::Request->new( $method, $uri, [ content_type => 'application/json' ], to_json($data) );
    }
    else {
        confess "Method $method unknown when requesting URL $uri";
    }

    $self->log->debug("$method request for $uri");
    if ( $data ) {
        $self->log->debug( sub { "Request data: " . to_json( $data ) } );
    }
    my $response = $self->ua->request($request);
    if ( $response->is_success ) {
        # DELETE method does not return JSON.
        return $method eq 'DELETE' ? 1 : from_json( $response->content );
    }

    my $err_msg = "$method $uri: " . $response->status_line;

    if ( my $content = $response->content ) {
        $err_msg .= "\n $content";
    }

    confess $err_msg;
}

{
    my $meta = __PACKAGE__->meta;

    foreach my $key ( qw( allele targeting_vector es_cell genbank_file distribution_qc ) ) {
#        $meta->add_method(
#            "find_$key" => sub {
#                my ( $self, $params ) = @_;
#                return $self->request( 'GET', sprintf( 'targ_rep/%ss.json', $key ), $params );
#            }
#        );

        $meta->add_method(
            "find_$key" => sub {
                my ( $self, $params ) = @_;

                my $user = $self->username;
                my $passw = $self->password;
                my @query = keys %$params;
                my $value = $params->{$query[0]};
                my $url = sprintf("%starg_rep/%ss.json?%s=%s", $self->base_url, $key, $query[0], $value);
                my $arr_resp = [];

                if ($key =~ /genbank_file/) {
                    if ($params->{what} =~ 'escell_clone') {
                        $url = sprintf("https://www.i-dcc.org/imits/targ_rep/alleles/%s/escell-clone-genbank-file", $params->{allele_id});
                    } elsif ($params->{what} =~ 'targeting_vector') {
                        $url = sprintf("https://www.i-dcc.org/imits/targ_rep/alleles/%s/targeting-vector-genbank-file", $params->{allele_id});
                    }
                    my $sys_call = `curl --silent -u $user:$passw $url 2>&1`;
                    my @dehtml = split "<pre>", $sys_call;
                    my @genbank = split "//", $dehtml[1];

                    assert($genbank[0] =~ 'ORIGIN');
                    return $genbank[0];
                }

                my $sys_call = `curl --silent -u $user:$passw $url 2>&1`;

                if ($sys_call) {
                    my @arr1 = split /^\[/, $sys_call;
                    my @arr2 = split /\]$/, $arr1[1];

                    my $json_resp = JSON::decode_json($arr2[0]);

                    $arr_resp->[0] = $json_resp;
                }
                return $arr_resp;
            }
        );

        $meta->add_method(
            "update_$key" => sub {
                my ( $self, $id, $params ) = @_;
                return $self->request( 'PUT', sprintf( 'targ_rep/%ss/%d.json', $key, $id ), { "targ_rep_$key" => $params } );
            }
        );

        $meta->add_method(
            "create_$key" => sub {
                my ( $self, $params ) = @_;
                return $self->request( 'POST', sprintf( 'targ_rep/%ss.json', $key ), { "targ_rep_$key" => $params } );
            }
        );

        $meta->add_method(
            "delete_$key" => sub {
                my ( $self, $id ) = @_;
                return $self->request( 'DELETE', sprintf( 'targ_rep/%ss/%d.json', "targ_rep_$key", $id ) );
            }
        );
    }

    foreach my $key ( qw( mi_plan ) ) {
        $meta->add_method(
            "find_$key" => sub {
                my ( $self, $params ) = @_;
                return $self->request( 'GET', sprintf( '%ss.json', $key ), $params );
            }
        );

        $meta->add_method(
            "update_$key" => sub {
                my ( $self, $id, $params ) = @_;
                return $self->request( 'PUT', sprintf( '%ss/%d.json', $key, $id ), { "$key" => $params } );
            }
        );

        $meta->add_method(
            "create_$key" => sub {
                my ( $self, $params ) = @_;
                return $self->request( 'POST', sprintf( '%ss.json', $key ), { "$key" => $params } );
            }
        );

        $meta->add_method(
            "delete_$key" => sub {
                my ( $self, $id ) = @_;
                return $self->request( 'DELETE', sprintf( '%ss/%d.json', "$key", $id ) );
            }
        );
    }

    $meta->make_immutable;
}

1;

__END__
