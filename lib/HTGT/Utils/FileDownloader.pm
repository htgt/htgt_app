package HTGT::Utils::FileDownloader;

use strict;
use warnings FATAL => 'all';

use base 'Exporter';

BEGIN {
    our @EXPORT      = qw( download_url_to_tmp_file );
    our @EXPORT_OK   = @EXPORT;
    our %EXPORT_TAGS = ();
}

use LWP::UserAgent;
use File::Temp;
use Carp 'confess';

sub download_url_to_tmp_file {
    my ($url, $env_proxy) = @_;
    
    confess("no url given") unless $url;

    my $tmp      = File::Temp->new() or confess "create tmp file: $!";
    my $ua       = LWP::UserAgent->new();
    $ua->env_proxy if $env_proxy;
    my $response = $ua->get( $url, ':content_file' => $tmp->filename );
    unless ( $response->is_success ) {
        confess( "download $url failed: " . $response->status_line );
    }
    return $tmp;
}

1;
