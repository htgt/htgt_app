#!/usr/bin/env perl
#
# $Id: insert_shipping_dates.pl,v 1.1 2009-08-25 15:10:14 rm7 Exp $

use strict;
use warnings FATAL => 'all';

use Date::Format 'time2str';
use Date::Parse  'str2time';
use HTGT::DBFactory;
use Getopt::Long;
use Readonly;

sub usage {
    ( my $prog = $0 ) =~ s{^.*/}{};
    print STDERR "Usage: $prog [--commit] [--shipdate=...] [--centre=...] CENTRE.DATE [...]\n";
    exit 1;
}

my $dbh;

{
    Readonly my $INSERT_SHIPDATE => <<'EOT';
insert into plate_data ( plate_id, data_type, data_value, edit_user )
( select plate_id, ?, ?, ?
  from plate
  where plate.name = ?
)
EOT

    sub insert_shipdate {
        my ( $plate_name, $data_type, $shipping_date ) = @_;
        if ( row_exists( $plate_name, $data_type ) ) {
            warn "$data_type already exists for $plate_name\n";
            return;
        }
        my $sth = $dbh->prepare_cached( $INSERT_SHIPDATE );
        my $count = $sth->execute( $data_type, $shipping_date, $ENV{USER}, $plate_name );
        if ( $count == 1 ) {
            warn "Inserted $plate_name $data_type $shipping_date\n";
        }
        else {
            warn "Failed to insert $plate_name $data_type $shipping_date\n";
        }
    }
}

{
    Readonly my $SELECT_SHIPDATE => <<'EOT';
select plate_data_id
from plate_data
join plate on plate.plate_id = plate_data.plate_id and plate.name = ?
where plate_data.data_type = ?
EOT

    sub row_exists {
        my ( $plate_name, $data_type ) = @_;
        my $sth = $dbh->prepare_cached( $SELECT_SHIPDATE );
        $sth->execute( $plate_name, $data_type );
        scalar @{ $sth->fetchall_arrayref };
    }
}

{
    Readonly my $DELETE_SHIPDATE => <<'EOT';
delete from plate_data
where plate_id in ( select plate_id from plate where name = ? )
and data_type = ?
and data_value = ?
EOT

    sub delete_shipdate {
        my ( $plate_name, $data_type, $shipping_date ) = @_;
        my $sth = $dbh->prepare_cached( $DELETE_SHIPDATE );
        my $count = $sth->execute( $plate_name, $data_type, $shipping_date );
        if ( $count == 1 ) {
            warn "Deleted $plate_name $data_type $shipping_date\n";
        }
        else {
            warn "Failed to delete $plate_name $data_type $shipping_date\n";
        }
    }
    
}

my ( $shipdate, $centre, $commit, $delete );
GetOptions( 'shipdate=s'   => \$shipdate,
            'centre=s'     => \$centre,
            'commit|c'     => \$commit,
            'delete'       => \$delete,
) or usage();

unless ( $centre and $shipdate ) {
    ( $shipdate, $centre ) = split '\.', $ARGV[0]
        or usage();
}

die "Invalid centre '$centre'"
    unless $centre eq 'csd' or $centre eq 'hzm';
my $data_type = "ship_date_$centre";

my $shiptime = str2time( $shipdate );
die "Invalid shipdate '$shipdate'"
    unless defined $shiptime;
$shipdate = uc time2str( '%d-%h-%y', $shiptime );

$dbh = HTGT::DBFactory->dbi_connect( 'eucomm_vector', {AutoCommit => 0} );

END {
    $dbh and do { eval { $dbh->rollback }; $dbh->disconnect };
}

my $doit = $delete ? \&delete_shipdate : \&insert_shipdate;

while ( <> ) {
    chomp( my $plate_name = $_ );
    $doit->( $plate_name, $data_type, $shipdate );
}

if ( $commit ) {
    $dbh->commit;
}
else {
    $dbh->rollback;
}

