#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/rearray-epds.pl $
# $LastChangedRevision: 7301 $
# $LastChangedDate: 2012-05-24 13:37:12 +0100 (Thu, 24 May 2012) $
# $LastChangedBy: sp12 $
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use HTGT::Utils::Plate::Create 'create_plate';
use HTGT::DBFactory;
use Const::Fast;
use Log::Log4perl ':easy';
use Perl6::Slurp 'slurp';
use List::MoreUtils qw( uniq firstidx );

# Signal to create_plate() that a well is empty
const my $EMPTY_WELL => [ '-' ];

# First column of 96-well plate left empty
const my $WELLS_PER_REPD => 96 - 8;

# List of REPD wells in the order we fill them
const my @REPD_WELLS => map { my $col=$_; map $_.$col, "A".."H" } "01".."12";

const my $REARRAY_PLATE_TYPE => 'REPD';

const my $EPD_FOR_MARKER_QUERY => <<'EOT';
select distinct epd_plate.name as plate_name, epd_well.well_name as well_name
from plate epd_plate
join well epd_well on epd_well.plate_id = epd_plate.plate_id
join well ep_well on ep_well.well_id = epd_well.parent_well_id
join plate ep_plate on ep_plate.plate_id = ep_well.plate_id
join project on project.design_instance_id = ep_well.design_instance_id
join mgi_gene on mgi_gene.mgi_gene_id = project.mgi_gene_id
where ep_plate.type = 'EP'
and epd_plate.type = 'EPD'
and epd_plate.name like 'EPD%'
and mgi_gene.marker_symbol = ?
EOT

const my $EPD_FOR_DESIGN_QUERY => <<'EOT';
select distinct epd_plate.name as plate_name, epd_well.well_name as well_name
from plate epd_plate
join well epd_well on epd_well.plate_id = epd_plate.plate_id
join well ep_well on ep_well.well_id = epd_well.parent_well_id
join plate ep_plate on ep_plate.plate_id = ep_well.plate_id
join design_instance on design_instance.design_instance_id = ep_well.design_instance_id
where ep_plate.type = 'EP'
and epd_plate.type = 'EPD'
and epd_plate.name like 'EPD%'
and design_instance.design_id = ?
EOT

const my $EPD_FOR_MARKER_SYMBOL_AND_PLATE_NAME => <<'EOT';
select distinct epd_plate.name as plate_name, epd_well.well_name as well_name
from plate epd_plate
join well epd_well on epd_well.plate_id = epd_plate.plate_id
join well ep_well on ep_well.well_id = epd_well.parent_well_id
join plate ep_plate on ep_plate.plate_id = ep_well.plate_id
join project on project.design_instance_id = ep_well.design_instance_id
join mgi_gene on mgi_gene.mgi_gene_id = project.mgi_gene_id
where ep_plate.type = 'EP'
and epd_plate.type = 'EPD'
and epd_plate.name = ?
and mgi_gene.marker_symbol = ?
EOT

{
    my $log_level = $WARN;

    GetOptions(
        'help'             => sub { pod2usage( -verbose    => 1 ) },
        'man'              => sub { pod2usage( -verbose    => 2 ) },
        'debug'            => sub { $log_level = $DEBUG },
        'verbose'          => sub { $log_level = $INFO },
        'commit'           => \my $commit,
        'start-with=s'     => \my $start_with,
        'designs!'         => \my $by_design,
        'epd-plate-names!' => \my $by_epd_plate_names,
    ) or pod2usage(2);

    die "--start-with name of first plate to be created must be specified\n"
        unless $start_with;
    
    Log::Log4perl->easy_init( { level => $log_level, layout => '%p %m%n' } );

    my @design_ids_or_marker_symbols = uniq slurp $ARGV[0], { chomp => 1 }
        or die "Nothing to do!\n";
        
    my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

    $htgt->txn_do(
        sub {
            my $epds_for_rearray = get_epds_for_rearray( $htgt, \@design_ids_or_marker_symbols, $by_design, $by_epd_plate_names );
            rearray_epds( $htgt, $start_with, $epds_for_rearray );
            unless ( $commit ) {
                WARN "Rollback";
                $htgt->txn_rollback;
            }
        }
    );
}

sub get_epds_for_rearray {
    my ( $htgt, $ids, $by_design, $by_epd_plate_names ) = @_;

    my $query;
   
    #TODO Add option for by_epd_plate_names plus by_designs?
    if ( $by_epd_plate_names ) {
        DEBUG( "Given EPD plate names plus marker symbols" );
        $query = $EPD_FOR_MARKER_SYMBOL_AND_PLATE_NAME;
    }
    elsif ( $by_design ) {
        DEBUG( "Searching for EPDs for design_ids" );
        $query = $EPD_FOR_DESIGN_QUERY;
    }
    else {
        DEBUG( "Searching for EPDs for marker symbols" );
        $query = $EPD_FOR_MARKER_QUERY;
    }
    
    my @epds_for_rearray;
    
    for my $id ( @{ $ids } ) {
        my $epd_wells;

        if ( $by_epd_plate_names ) {
            my ( $marker_symbol, $epd_plate_name ) = split ',', $id;
            $epd_wells = $htgt->storage->dbh_do(
                sub {                
                    $_[1]->selectall_hashref( $query, [ 'PLATE_NAME', 'WELL_NAME' ],
                        undef, $epd_plate_name, $marker_symbol );
                }
            );
        }
        else {
            $epd_wells = $htgt->storage->dbh_do(
                sub {                
                    $_[1]->selectall_hashref( $query, [ 'PLATE_NAME', 'WELL_NAME' ],
                        undef, $id );
                }
            );
        }

        if ( keys %{$epd_wells} ) {
            DEBUG( "Found $id on plates " . join( q{,}, keys %{$epd_wells} ) );  
            push @epds_for_rearray, $epd_wells;
        }
        else {
            ERROR( "No EPD wells for $id" );
        }
    }

    return \@epds_for_rearray;
}

sub rearray_epds {
    my ( $htgt, $start_with_plate_name, $epds_for_rearray ) = @_;

    my $plate_name = $start_with_plate_name;
    
    for my $repd ( @{ group_into_repds( $epds_for_rearray ) } ) {
        INFO( "Creating plate $plate_name with " . @{$repd} . ' wells' );
        create_plate(
            $htgt,
            plate_name => $plate_name,
            plate_type => $REARRAY_PLATE_TYPE,
            plate_data => plate_data_for( $repd ), 
            created_by => $ENV{USER}
        );
        $plate_name++;
    }
}

sub plate_data_for {
    my $raw_data = shift;

    # Start with an empty plate, keyed on well_name
    my %plate = map { $_ => $EMPTY_WELL } @REPD_WELLS;

    # Populate with the data for this plate. Index starts at 8 as we leave the
    # first column empty (for the control)
    my $ix = 8;
    for ( @{$raw_data} ) {
        $plate{ $REPD_WELLS[$ix++] } = [ @{$_}{ qw( PLATE_NAME WELL_NAME ) } ];
    }

    # Sort the wells into the order A01, ..., A12, ..., H01, ..., H12
    # expected by create_plate() - luckily for us, this is the default
    # lexical string sort

    return [ @plate{ sort @REPD_WELLS } ];
}

sub group_into_repds {
    my ( $epds_for_rearray ) = @_;

    DEBUG( "Grouping EPDs into re-array plates" );
    
    my @repds;

    my @this_repd;
    
    for my $plate_group ( map values %{$_}, @{$epds_for_rearray} ) {
        my @wells = sort_by_column( $plate_group );
        while ( @wells > $WELLS_PER_REPD ) {
            DEBUG( "Splitting single EPD plate over multiple REPDs" );
            push @repds, [ splice @wells, 0, $WELLS_PER_REPD ];
        }
        if ( @this_repd + @wells <= $WELLS_PER_REPD ) {
            push @this_repd, @wells;
        }
        else {
            DEBUG( 'Creating plate with ' . @this_repd . ' wells' );            
            push @repds, [ @this_repd ];
            @this_repd = @wells;         
        }
    }

    if ( @this_repd ) {
        DEBUG( 'Creating plate with ' . @this_repd . ' wells' );
        push @repds, \@this_repd;
    }
    
    return \@repds;
}

sub sort_by_column {
    my $plate_group = shift;

    map $_->[0],
        sort { $a->[1] <=> $b->[1] }
            map [ $_, index_of($_) ], values %{$plate_group};
}

sub index_of {
    my $well = shift;

    my ( $well_name ) = $well->{WELL_NAME} =~ /_([A-H]\d+)$/
        or die "Failed to parse well name: $well->{WELL_NAME}";

    return firstidx { $well_name eq $_ } @REPD_WELLS;
}

__END__

=head1 NAME

re-array-epds.pl - Describe the usage of script briefly

=head1 SYNOPSIS

re-array-epds.pl [options] [input_file]

      --help                Display help page
      --man                 Display the manual page
      --debug               Show debug logging
      --verbose             Show verbose logging
      --commit              Commit changes to database
      --start-with          Name of first plate to create
      --designs!            Input file contains design-ids, not gene marker symbols
      --epd-plate-names!    User has specified EPD plate names where epd wells can be found

=head1 DESCRIPTION

This script re-arrays EPD wells into newly created REDP plates.

The EPD wells can be identified by either gene marked symbols or design ids.

It is also possible to specify a specific EPD plate where the wells can be found for a given marked symbol.

Multiple input types are accepted. By default a list of gene marker symbols is passed in.

If the --designs option is given then the script expects a list of design ids.

If the --epd-plate-names option is given then a EPD plate name should be specified along with the marker symbol in this format:
marker_symbol,epd_plate_name


=head1 AUTHOR

Ray Miller, E<lt>rm7@htgt-web.internal.sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Ray Miller

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
