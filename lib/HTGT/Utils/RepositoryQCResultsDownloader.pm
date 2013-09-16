
use MooseX::Declare;

class HTGT::Utils::RepositoryQCResultsDownloader {

    use Moose::Util::TypeConstraints;
    use URI;
    use File::Temp;
    use Log::Log4perl ':easy';
    
    use WWW::Mechanize;

    subtype 'HTGT::Utils::URI' => as class_type 'URI';
    
    coerce 'HTGT::Utils::URI'
        => from 'Str'
        => via { URI->new( $_ ) };

    has proxy_url => (
        is       => 'rw',
        isa      => 'HTGT::Utils::URI',
        coerce   => 1,
        required => 1,
        default  => sub { URI->new( 'http://wwwcache.sanger.ac.uk:3128/' ) }
    );

    has download_url => (
        is       => 'rw',
        isa      => 'HTGT::Utils::URI',
        coerce   => 1,
        required => 1,
    );

    has login_url => (
        is       => 'rw',
        isa      => 'HTGT::Utils::URI',
        coerce   => 1,
        required => 1,
    );

    has username => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    has password => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    has timeout => (
        is       => 'rw',
        isa      => 'Int',
        required => 1,
        default  => 180
    );
    
    method fetch () {

        INFO( "Fetching data from " . $self->download_url );
                
        my $mech = WWW::Mechanize->new;

        if ( my $proxy = $self->proxy_url ) {
            $mech->proxy( [ 'http', 'https', 'ftp' ] => $proxy );
        }

        if ( defined( my $timeout = $self->timeout ) ) {
            $mech->timeout( $timeout );
        }
        
        $mech->get( $self->login_url );

        DEBUG( "Submitting login details" );
        $mech->submit_form(
            with_fields => {
                loginID  => $self->username,
                password => $self->password
            }
        );

        my $tmp = File::Temp->new();

        DEBUG( "Submitting GET request for " . $self->download_url );
        my $response = $mech->get( $self->download_url );
        unless ( $response->is_success ) {
            confess "failed to fetch " . $self->download_uri . ": " . $response->status_line;
        }
	    print $tmp $mech->content;
        DEBUG( "GET OK" );
        
        $tmp->close
            or confess "close temporary file: $!";
    
        return $tmp;
    }
}
    
1;

__END__

=head1 NAME

RepositoryQCResultsDownloader - Perl extension for blah blah blah

=head1 SYNOPSIS

   use RepositoryQCResultsDownloader;
   blah blah blah

=head1 DESCRIPTION

Stub documentation for RepositoryQCResultsDownloader, 

Blah blah blah.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Ray Miller, E<lt>rm7@hpgen-1-14.internal.sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Ray Miller

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
