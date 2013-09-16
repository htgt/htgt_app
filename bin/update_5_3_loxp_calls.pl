#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/update_5_3_loxp_calls.pl $
# $LastChangedRevision: 4836 $
# $LastChangedDate: 2011-04-21 09:42:23 +0100 (Thu, 21 Apr 2011) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory;
use Log::Log4perl ':easy';
use Perl6::Slurp 'slurp';
use Parallel::Simple 'prun';

{    
    my $log_level = $WARN;
    my $commit    = 0;
    my $stdin     = 0;
    my $nprocs    = 1;

    GetOptions(
        'help'       => sub { pod2usage( -verbose => 1 ) },
        'man'        => sub { pod2usage( -verbose => 2 ) },
        'debug'      => sub { $log_level = $DEBUG },
        'verbose'    => sub { $log_level = $INFO },
        'commit'     => \$commit,
        'stdin'      => \$stdin,
        'nprocs=i'   => \$nprocs,
    ) or pod2usage(2);

    Log::Log4perl->easy_init( {
        level  => $log_level,
        layout => '%d %P %m%n'
    } );

    my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

    my @plate_names;
    if ( $stdin ) {
        @plate_names = slurp \*STDIN, { chomp => 1 };
    }
    elsif ( @ARGV ) {
        @plate_names = @ARGV;
    }
    else {
        @plate_names = map { $_->name } $htgt->resultset( 'Plate' )->search( { type => 'EPD' } );
    }

    INFO( @plate_names . ' plates to process' );
    my @plate_groups = partition( \@plate_names, $nprocs );

    prun( map [ \&update_5_3_loxp_calls, $htgt, $_, $commit ], @plate_groups )
        or die Parallel::Simple::errplus;
}

sub update_5_3_loxp_calls {
    my ( $htgt, $plate_names, $commit ) = @_;

    INFO( 'Handling ' . @{$plate_names} . ' plates' );
    $htgt->txn_do(
        sub {    
            my $well_rs = $htgt->resultset( 'Well' )->search( { 'plate.name' => $plate_names }, { join => 'plate' } );

            while ( my $well = $well_rs->next ) {
                DEBUG( "Updating 5' arm, 3' arm, and LoxP pass levels for $well" );
                for ( qw( three_arm_pass_level five_arm_pass_level loxP_pass_level ) ) {
                    $well->$_( 'recompute' );         
                }
            }

            if ( not $commit ) {
                WARN "Rollback";
                $htgt->txn_rollback;
            }
        }
    );    
}

sub partition {
    my ( $array_ref, $num_parts ) = @_;

    if ( $num_parts == 1 ) {
        return $array_ref;
    }

    my @parts;
    
    my $part_no = 0;
    for ( @{$array_ref} ) {
        push @{ $parts[$part_no] }, $_;
        $part_no = ( $part_no + 1 ) % $num_parts;
    }

    return @parts;
}

__END__

=head1 NAME

update_5_3_loxp_calls.pl - Describe the usage of script briefly

=head1 SYNOPSIS

update_5_3_loxp_calls.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for update_5_3_loxp_calls.pl, 

=head1 AUTHOR

Ray Miller, E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Genome Research Ltd

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
