#!/usr/bin/env perl
# update_repository_qc_results.pl --- Download latest QC results from KOMP respository and update HTGT database
# Author: Ray Miller <rm7@sanger.ac.uk>
# 
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/update_repository_qc_results.pl $
# $LastChangedRevision: 7591 $
# $LastChangedDate: 2012-09-05 11:51:52 +0100 (Wed, 05 Sep 2012) $
# $LastChangedBy: mqt $

use warnings FATAL => 'all';
use strict;

use Config::General;
use Getopt::Long;
use HTGT::DBFactory;
use HTGT::Utils::RepositoryQCResultsDownloader;
use HTGT::Utils::RepositoryQCResultsUpdater;
use HTGT::Utils::RepositoryQCtoTargrep;
use Log::Log4perl ':easy';
use Pod::Usage;
use Readonly;
use Getopt::Long;
use Try::Tiny;
use Path::Class 'file';

{
    Readonly my $DEFAULT_CONFFILE => '/software/team87/brave_new_world/conf/komp_qc_download.conf';

    my $conffile            = $DEFAULT_CONFFILE;
    my $loglevel            = $WARN;
    my $input_file          = undef;
    my $previous_input_file = undef;
    my $update_htgt         = 0;
    my $update_targ_rep     = 0;

    GetOptions(
        'help'             => sub { pod2usage( -verbose => 1 ) },
        'man'              => sub { pod2usage( -verbose => 2 ) },
        'debug'            => sub { $loglevel = $DEBUG },
        'verbose'          => sub { $loglevel = $INFO },
        'config=s'         => \$conffile,
        'file=s'           => \$input_file,
        'previous-file=s'  => \$previous_input_file,
        'update-htgt!'     => \$update_htgt,
        'update-targ-rep!' => \$update_targ_rep,
    ) or pod2usage(2);

    Log::Log4perl->easy_init( $loglevel );

    # fetch() returns a File::Temp object that will be deleted when the object
    # goes out of scope, so we bind it at the top level to ensure the underlying
    # file doesn't get deleted on us:
    my $qc_results;

    unless ( $input_file ) {
        my $config = Config::General->new( $conffile );
        my $downloader = HTGT::Utils::RepositoryQCResultsDownloader->new( $config->getall );
        $qc_results = $downloader->fetch;
        $input_file = $qc_results->filename;
    }

    my $difference_file = defined $previous_input_file ?
        create_difference_file( $input_file, $previous_input_file ) : $input_file;

    if ( $update_htgt ) {
        try {
            update_htgt( $difference_file );
        }
        catch {
            ERROR( $_ );
        };
    }

    if ( $update_targ_rep ) {
        try {
            update_targ_rep( $difference_file );
        }
        catch {
            ERROR( $_ );
        };
    }
}

sub update_htgt {
    my $input_file = shift;

    my $updater = HTGT::Utils::RepositoryQCResultsUpdater->new(
        {
            filename => $input_file,
            schema   => HTGT::DBFactory->connect( 'eucomm_vector', {AutoCommit => 1} ),
        }
    );
    $updater->update();
}

sub update_targ_rep {
    my $input_file = shift;

    HTGT::Utils::RepositoryQCtoTargrep::load_qc_to_targrep( $input_file );
}

sub create_difference_file{
    my ( $current_filename, $previous_filename ) = @_;

    my %previous_lines;
    my $previous_file = file( $previous_filename );
    my $previous_fh = $previous_file->openr();
    while ( my $previous_line = $previous_fh->getline() ){
        $previous_lines{ $previous_line}++;
    }

    my $current_file = file( $current_filename );
    my $current_fh = $current_file->openr();
    my $difference_file = file( 'komp_dump_updates.csv' );
    my $difference_fh = $difference_file->openw();
    my $header = $current_fh->getline();
    $difference_fh->print( $header );
    while ( my $current_line = $current_fh->getline() ){
        $difference_fh->print( $current_line ) unless defined $previous_lines{ $current_line };
    }

    return 'komp_dump_updates.csv';
}

__END__

=head1 NAME

update_repository_qc_results.pl - download QC results from KOMP and update HTGT database

=head1 SYNOPSIS

  update_repository_qc_results.pl [options]

      --config      Specify path to configuration file

=head1 DESCRIPTION

This script downloads QC results from the KOMP repository and
inserts/updates records in the HTGT REPOSITORY_QC_RESULT table.

=head1 CONFIGURATION

Download URL and authentication parameters are read from a
configuration file (default
C</software/team87/brave_new_world/conf/komp_qc_download.conf>).

=head1 SEE ALSO

L<HTGT::Utils::RepositoryQCDownloader>, L<HTGT::Utils::RepositoryQCUpdater>,
L<Config::General>.

=head1 AUTHOR

Ray Miller, E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Wellcome Trust Sanger Institute

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
