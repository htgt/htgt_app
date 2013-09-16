#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/set_vector_distribute.pl $
# $LastChangedRevision: 1734 $
# $LastChangedDate: 2010-05-17 13:56:30 +0100 (Mon, 17 May 2010) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use Readonly;
use Config::Scoped;
use Log::Log4perl ':easy';
use Getopt::Long;
use Pod::Usage;
use Readonly;

Readonly my $EDIT_USER => $ENV{USER};

Readonly my $DEFAULT_CONFFILE => '/software/team87/brave_new_world/conf/vector_distribute.conf';

my $log_level = $WARN;

GetOptions(
    'help'     => sub { pod2usage( -verbose => 1 ) },
    'man'      => sub { pod2usage( -verbose => 2 ) },
    'debug'    => sub { $log_level = $DEBUG },
    'verbose'  => sub { $log_level = $INFO },
    'config=s' => \my $conffile,
    'delete'   => \my $delete,
    'commit'   => \my $commit,
) or pod2usage(2);

$conffile ||= $DEFAULT_CONFFILE;

Log::Log4perl->easy_init( {
    level  => $log_level,
    layout => '%p %m%n',
} );

my $config = Config::Scoped->new( file => $conffile, warnings => { permissions => 'off' } )->parse;

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );
INFO( sprintf( 'Connected to %s, %s mode', $htgt->storage->dbh->{Name}, $commit ? 'COMMIT' : 'ROLLBACK' ) );

$htgt->txn_do(
    sub {
        set_vector_distribute();
        unless ( $commit ) {
            WARN( "Rollback" );
            $htgt->txn_rollback;
        }
    }
);

sub set_vector_distribute {

    my $wells = $htgt->resultset( 'Well' )->search(
        {
            'plate.type'            => [ 'PCS', 'PGD', 'PGR', 'PGS' ],
            'me.design_instance_id' => { '!=', undef },
        },
        {
            join     => 'plate',
            prefetch => 'well_data'
        }
    );    

    while ( my $well = $wells->next ) {
        my $type = get_type( $well ) or next;
        check_distribute( $well, $type );
    }
}

sub check_distribute {
    my ( $well, $type ) = @_;

    my $pass_level  = get_well_data( $well, 'pass_level' ) || '';
    my $distribute  = get_well_data( $well, 'distribute' ) || 'no';
    my $cassette    = get_well_data( $well, 'cassette' ) || '<undef>';
    my $design_type = $well->design_instance->design->design_type || 'KO';
    
    if ( grep { $pass_level eq $_ } @{ $config->{$type}->{distribute} } ) {
        return if $distribute eq 'yes';
        WARN( "set distribute flag for well $well with pass level $pass_level, cassette $cassette, design type $design_type" );
        set_distribute( $well, 'yes' );
    }
    else {
        return if $distribute eq 'no' or do_not_lower( $well );
        my $mesg = "delete distribute flag for well $well with pass level $pass_level, cassette $cassette, design type $design_type"; 
        if ( $delete ) {
            WARN( $mesg );
            set_distribute( $well, 'no' );            
        }
        else {
            INFO( "would $mesg" );
        }
    }
}

sub do_not_lower {
    my ( $well ) = @_;

    return unless $config->{exceptions} and $config->{exceptions}->{do_not_lower};
    
    for ( @{ $config->{exceptions}->{do_not_lower} } ) {
        return 1
            if $_ eq $well->stringify or $_ eq $well->plate->name;
    }

    return;
}

sub set_distribute {
    my ( $well, $distribute ) = @_;

    if ( $distribute eq 'no' ) {
        $well->well_data_rs->find( { data_type => 'distribute' } )->delete;
    }
    else {
        my $dist = $well->related_resultset( 'well_data' )->find_or_new( { data_type => 'distribute' } );
        $dist->data_value( 'yes' );
        $dist->edit_user( $EDIT_USER );
        $dist->edit_date( \'current_timestamp' );
        $dist->update_or_insert;        
    }
}

sub get_type {
    my $well = shift;

    if ( $well->plate->type eq 'PCS' ) {
        return 'pcs';
    }

    my $design_type = $well->design_instance->design->design_type || 'KO';
    if ( $design_type =~ /^Del/ ) {
        return 'pg_deletion';        
    }

    my $cassette = get_well_data( $well, 'cassette' );
    unless ( defined $cassette ) {
        ERROR( "well $well has no cassette" );
        return;
    }

    if ( $cassette =~ /[gs]t.$/ ) {
        return 'pg_promoterless';        
    }

    return 'pg_promoter';    
}

sub get_well_data {
    my ( $well, $data_type ) = @_;

    my ( $data_value ) = map $_->data_value, grep $_->data_type eq $data_type, $well->well_data;

    return $data_value;
}

__END__

=pod

=head1 NAME

set_vector_distribute

=head1 SYNOPSIS

  set_vector_distribute [OPTIONS]

  Options:

   --help      Display a brief help message
   --man       Display the manual page
   --debug     Log debug messages
   --verbose   Log informational messages
   --commit    Commit changes to the database (default is to rollback)
   --delete    Delete distribute flags that would not be set by this script (default is to ignore them)

=head1 DESCRIPTION

This script examines wells on PCS, PGD, PGR, and PGS plates and sets
(or deletes) the distribute flag according to the pass level for the
well.

Pass levels that trigger a vector becoming distributable are listed in
the configuration file.

=head1 FILES

The default configuration can be found in
C</software/team87/brave_new_world/conf/vector_distribute.conf>.

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Genome Research Ltd.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
