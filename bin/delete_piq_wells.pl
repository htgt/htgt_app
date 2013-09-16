#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use Getopt::Long;
use Log::Log4perl ':easy';
use Perl6::Slurp;
use Pod::Usage;

GetOptions(
    'help'   => sub { pod2usage( -verbose => 1 ) },
    'man'    => sub { pod2usage( -verbose => 2 ) },
    'commit' => \my $commit,
) and @ARGV == 1
    or pod2usage(2);

Log::Log4perl->easy_init( { level => $INFO, layout => '%p %x %m%n' } );

my $htgt = HTGT::DBFactory->connect('eucomm_vector');

my $filename = $ARGV[0];
my @well_names = split /\n/, slurp($filename);

for my $well_name ( @well_names ) {
    Log::Log4perl::NDC->remove;
    Log::Log4perl::NDC->push( $well_name );
    my $well = $htgt->resultset('Well')->find( { well_name => $well_name  }, { prefetch => [ 'plate', 'well_data' ] } );

    unless ( $well ) {
        ERROR("Unable to find well");
        next;
    }

    unless( $well->plate->type eq 'PIQ' ) {
        ERROR('Belongs to a ' . $well->plate->type . ' plate, will not delete ');
        next;
    }

    if( $well->child_wells->count ) {
        ERROR('Has child wells, can not delete');
        next;
    }

    $htgt->txn_do(
        sub {
            my $wd = $well->well_data->delete;
            $well->delete;
            INFO("Deleted $wd well_data rows and the well");
            unless ($commit) {
                INFO('Rollback');
                $htgt->txn_rollback;
            }
        }
    );
}

__END__

=head1 NAME

delete_piq_wells.pl - delete piq wells from htgt

=head1 SYNOPSIS

delete_piq_wells.pl.pl [options] input-file

      --help            Display help page
      --debug           Show debug logging
      --man             Display the manual page
      --commit          Delete the wells, by default all changes are rolled back

Input file is a newline seperated file of PIQ well names.

=head1 DESCRIPTION

This script deletes PIQ wells from the htgt database.
The input is a file listing the piq wells to delete.

Checks are carried out to make sure the well belongs to a PIQ plate and has no child wells.

=head1 AUTHOR

Sajith Perera

=head1 BUGS

None reported... yet.

=headl TODO

=cut
