package HTGT;

use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
  Breadcrumbs
  ConfigLoader
  Static::Simple
  StackTrace
  Session
  Session::State::Cookie
  Session::Store::DBI
  Authentication
  Authorization::Roles
  Prototype
  LogUtils
  Cache
  RequireSSL
  /;

extends 'Catalyst';

use Log::Log4perl::Catalyst;

if ( defined $ENV{LOG4PERL} ) {
    __PACKAGE__->log( Log::Log4perl::Catalyst->new( $ENV{LOG4PERL} ) );
}
else {
    __PACKAGE__->log( Log::Log4perl::Catalyst->new() );
}

#Session::Store::FastMmap

# Configure the application.
#
# Note that settings in HTGT.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name           => 'HTGT',
    require_ssl    => {
        https => $ENV{HTGT_HTTPS_DOMAIN} || 'www.sanger.ac.uk',
        http  => $ENV{HTGT_HTTP_DOMAIN} || 'www.sanger.ac.uk',
        remain_in_ssl => 1,
        no_cache => 0,
        detach_on_redirect => 0,
        disabled => $ENV{HTGT_ENABLE_HTTPS} ? 0 : 1,
    },
    enable_catalyst_header => 1,
    using_frontend_proxy => 1,
    authentication => {
        default_realm => 'ssso',
        realms        => {
        	lims2 => {
        		credential => {
        			class          => 'LIMS2Cookie',
        			username_field => 'auth_user_name',
        		},
                store => {
                    class         => 'LIMS2Store',
                },
        	},        	
            ssso => {
                credential => {
                    class          => 'SangerSSO',
                    username_field => 'auth_user_name',
                },
                store => {
                    class         => 'DBIx::Class',
                    user_model    => 'HTGTDB::AuthUser',
                    id_field      => 'auth_user_name',
                    role_relation => 'roles',
                    role_field    => 'auth_role_name',
                    ignore_fields_in_find => [ 'id' ]
                },
            },
            ssso_fallback => {
                credential => {
                    class          => 'SangerSSO',
                    username_field => 'auth_user_name'
                },
                store => {
                    class => 'Null'
                }
            },
            qc => {
            	credential => {
            		class => 'Password',
            		password_field => 'password',
            		password_type => 'salted_hash',
            		password_salt_len => 4
            	},
            	store => {
            		class => 'Minimal',
            		users => {
            			lims2 => {
            			   password => "{SSHA}UxvBXrR7VJ+XGFiQ+/R1s6CEL3x4RlNF",
            			}
            		}
            	}
            } 
        }
    },
  'Plugin::Cache' => {
      backends => {
          default => {
              cache_root      => $ENV{HTGT_CACHE_ROOT},
              class           => 'Cache::File',
              default_expires => '8 hours',
          }
      }
  },
);

# Start the application
__PACKAGE__->setup;

after uri_for => sub {
    my ($self, $path, @args) = @_;

    my $base = $self->req->base;
    $base =~ s/^http:/https:/;
    $self->req->base(URI->new($base));
    $self->req->secure(1);

    return;
};

sub secure_uri_for {
    my ($self, @args) = @_;

    my $uri = $self->uri_for(@args);
    $uri->scheme('https');

    return $uri;
}

=head1 NAME

HTGT - Catalyst based application

=head1 SYNOPSIS

    script/htgt_server.pl

=head1 DESCRIPTION

Sanger Institute's Team87's High Throughput Gene Targetting webapp

=head1 SEE ALSO

L<HTGT::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Vivek Iyer

David K Jackson <david.jackson@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
