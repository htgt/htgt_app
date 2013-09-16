#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use sigtrap die    => 'normal-signals';

use HTGT::DBFactory;
use Getopt::Long;
use Pod::Usage;
use Readonly;

my $DB_USER = 'eucomm_vector';

{
    my $verbose;

    sub set_verbose {
        $verbose = 1;
    }

    sub verbose {
        return unless $verbose;
        print STDERR "$_[0]\n";
    }
}

sub update_synonym {
    my ( $dbh, $synonym_name, $table_name ) = @_;

    $synonym_name = $dbh->quote_identifier( uc( $DB_USER ), uc( $synonym_name ) );
    $table_name   = $dbh->quote_identifier( uc( $DB_USER ), uc( $table_name ) );

    verbose( "Creating synonym $synonym_name for $table_name" );
    $dbh->do( "CREATE OR REPLACE SYNONYM $synonym_name FOR $table_name" );
}

sub delete_synonym {
    my ( $dbh, $synonym_name ) = @_;

    $synonym_name = $dbh->quote_identifier( uc( $DB_USER ), uc( $synonym_name ) );
    
    verbose( "Deleting synonym $synonym_name" );
    $dbh->do( "DROP SYNONYM $synonym_name" );
}

sub show_synonym {
    my ( $dbh, $synonym_name ) = @_;
    my ( $table_name ) = $dbh->selectrow_array( <<'EOT', {}, uc( $DB_USER ), uc( $synonym_name ) );
SELECT TABLE_NAME
FROM USER_SYNONYMS
WHERE TABLE_OWNER = ?
AND SYNONYM_NAME = ?
EOT
    die "No such synonym: $synonym_name\n"
        unless defined $table_name;
    print "$table_name\n";
}

my $handler = \&show_synonym;
GetOptions(
    'help'           => sub { pod2usage( -verbose => 1 ) },
    'man'            => sub { pod2usage( -verbose => 2 ) },
    'update'         => sub { $handler = \&update_synonym },
    'delete'         => sub { $handler = \&delete_synonym },
    'verbose|v'      => \&set_verbose,
) or pod2usage( 2 );

my $synonym_name = shift @ARGV;
pod2usage( "synonym name not specified" )
    unless defined $synonym_name;

my $table_name = shift @ARGV;
pod2usage( "table name not specified" )
    if $handler == \&update_synonym and not defined $table_name;

my $dbh = HTGT::DBFactory->dbi_connect( 'eucomm_vector' );

$handler->( $dbh, $synonym_name, $table_name );

__END__

=pod

=head1 NAME

manage_synonym

=head1 SYNOPSIS

manage_synonym [--verbose] [--production] SYNONYM_NAME

manage_synonym [--verbose] [--production] --update SYNONYM_NAME TABLE_NAME

manage_synonym [--verbose] [--production] --delete SYNONYM_NAME

=head1 OPTIONS

=over 4

=item B<--help>

Show brief help message

=item B<--man>

Show manual page

=item B<--production>/B<--L>

Connect to live database (default is to connect to test database)

=item B<--verbose>

Be more verbose

=item B<--update>

Create or replace synonym B<SYNONYM_NAME> with a pointer to the B<TABLE_NAME>.

=item B<--delete>

Drop synonym B<SYNONYM_NAME>.

=back

=head1 DESCRIPTION

B<manage_synonym>  can be used to view, update or delete a synonym.  If neither
B<--update> nor B<--delete> is specified, the current table pointed to by B<SYNONYM_NAME> is
displayed.

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>

=cut

