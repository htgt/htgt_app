#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/data_pump.pl $
# $LastChangedRevision: 6488 $
# $LastChangedDate: 2011-12-06 12:57:15 +0000 (Tue, 06 Dec 2011) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use Log::Log4perl ':easy';
use Lingua::EN::Inflect 'PL_N';
use Const::Fast;
use Config::General;
use File::Temp;
use DateTime;
use IPC::System::Simple 'systemx';
use Term::ReadPassword;
use Try::Tiny;
use DBI;

const my $DEFAULT_CONFFILE => '/software/team87/brave_new_world/conf/data_pump.conf';

const my @REQUIRED_CONFIG_PARAMS => qw( src_database
                                        dest_database
                                        dpump_user
                                        expdp
                                        impdp
                                        sqlplus
                                        common_param
                                  );

const my $DROP_DATABASE_PLSQL => <<'EOT';
WHENEVER SQLERROR EXIT FAILURE;

CREATE OR REPLACE procedure app_drop_database AS

cursor database_name is
select
  property_value db_name
from
  database_properties
where
  property_name='GLOBAL_DB_NAME';

db_name varchar2(30);

cursor all_dropable_objects is
select 'drop sequence ":schema".'||sequence_name sql_text
from dba_sequences
where sequence_owner = ':schema'
union all
select 'drop view ":schema".'||view_name sql_text
from dba_views
where owner = ':schema'
union all
select 'drop snapshot ":schema".'||name sql_text
from dba_snapshots
where owner = ':schema'
union all
select 'drop type ":schema".'||type_name sql_text
from dba_types
where owner = ':schema'
union all
select 'drop synonym ":schema".'||synonym_name sql_text
from dba_synonyms
where owner = ':schema'
union all
select 'drop function ":schema".'||object_name sql_text
from dba_objects where object_type = 'FUNCTION' and owner = ':schema'
union all
select 'drop procedure ":schema".'||object_name sql_text
from dba_objects where object_type = 'PROCEDURE' and owner = ':schema' and object_name != 'APP_DROP_DATABASE' 
union all
select 'drop package ":schema".'||object_name sql_text
from dba_objects where object_type = 'PACKAGE' and owner = ':schema'
union all
select 'drop table ":schema".'||table_name||' cascade constraints purge' sql_text
from dba_tables where owner = ':schema';

begin 

    open database_name;
    fetch database_name into db_name;
    close database_name;
    
    if db_name = 'ESMP.WORLD' then
      raise_application_error(-20101, 'Cannot drop production database');
    else    
      for drop_command in all_dropable_objects loop
        begin
          dbms_output.put_line('Debug ' || drop_command.sql_text);
          execute immediate drop_command.sql_text; 
        exception when others then
           raise_application_error(-20102, 'Command not executed: ' || SQLERRM );
        end;
      end loop;
    end if;
end;
/

begin
app_drop_database;
end;
/

exit;
EOT

const my $SELECT_SEQUENCES_SQL => <<'EOT';
select * from dba_sequences
where sequence_owner = %s
EOT

const my $SELECT_CURVAL_SQL    => <<'EOT';
select %s.nextval from dual
EOT
    
    const my $DROP_SEQUENCE_SQL    => <<'EOT';
drop sequence %s
EOT

# I know it's icky to interpolate number with %s, but Oracle's numbers
# don't fit into an unsigned long, so we can't use %lu.
const my $CREATE_SEQUENCE_SQL  => <<'EOT';
CREATE SEQUENCE %s
MINVALUE %s
MAXVALUE %s
INCREMENT BY %s
START WITH %s
%s
%s
%s
EOT


{
    my $conffile  = $DEFAULT_CONFFILE;
    my $log_level = $WARN;
    my $doit      = 0;
    my $dumpall   = 0;
    my $keep      = 0;
    my $export    = 1;
    my $drop      = 1;
    my $import    = 1;
    my $sync_seq  = 1;    
    
    GetOptions(
        'help'            => sub { pod2usage( -verbose => 1 ) },
        'man'             => sub { pod2usage( -verbose => 2 ) },
        'debug'           => sub { $log_level = $DEBUG },
        'verbose'         => sub { $log_level = $INFO },
        'doit!'           => \$doit,
        'config=s'        => \$conffile,
        'keep!'           => \$keep,
        'all'             => \$dumpall,
        'export!'         => \$export,
        'drop!'           => \$drop,
        'import!'         => \$import,
        'sync-sequences!' => \$sync_seq
        
    ) or pod2usage(2);

    Log::Log4perl->easy_init( $log_level );
    
    my $config = read_config( $conffile );

    my @todo;
    if ( $dumpall ) {
        pod2usage( "Cannot specify schemas with --all option" ) if @ARGV;
        @todo = keys %{ $config->{schema} };
    }
    else {
        pod2usage( "No schemas specified" ) unless @ARGV;
        @todo = map { ensure_valid_schema( $config, $_ ) } @ARGV;
    }    

    my $password = read_password( "Password for $config->{dpump_user}: " )
        or die "No password - aborted\n";

    $config->{password}       = $password;
    $config->{dryrun}         = !$doit;
    $config->{unlink}         = !$keep;
    $config->{effective_date} = DateTime->now();
    $config->{export}         = $export;
    $config->{drop}           = $drop;
    $config->{import}         = $import;
    $config->{sync_sequences} = $sync_seq;

    if ( $config->{oracle_home} ) {
        $ENV{ORACLE_HOME}     = $config->{oracle_home};
        $ENV{LD_LIBRARY_PATH} = $ENV{ORACLE_HOME};
        $ENV{PERL5LIB}        = $ENV{ORACLE_HOME} . '/lib/perl5/5.8.8' . ':' . $ENV{PERL5LIB};
        if ( $config->{oracle_nls11} ) {
            delete $ENV{ORA_NLS10};
            $ENV{ORA_NLS11} = $ENV{ORACLE_HOME} . '/nls/data';
        }
        elsif ( $config->{oracle_nls10} ) {            
            delete $ENV{ORA_NLS11};
            $ENV{ORA_NLS10} = $ENV{ORACLE_HOME} . '/nls/data';
        }
    }

    INFO( sprintf 'Effective date %s %s (%d)', map { $config->{effective_date}->$_ } 'ymd', 'hms', 'epoch' );
    for my $schema_name ( @todo ) {
        try {
            dump_and_pump( $config, $schema_name );
        }
        catch {
            ERROR( $_ );            
        };                
    }
}

sub dump_and_pump {
    my ( $config, $schema_name ) = @_;
    
    INFO( "dump_and_pump schema $schema_name" );

    my $params = data_pump_params( $config, $schema_name );

    if ( $config->{export} ) {
        my $expdp_par  = generate_parfile( $config, $params, 'expdp_param' );
        INFO( "Running expdp with parameter file $expdp_par" );
        run( $config, 'expdp', connect_id( $config, 'src_database' ), "parfile=$expdp_par" );
    }

    if ( $config->{drop} ) {
        my $dropdb_sql = generate_sqlfile( $config, $schema_name );
        INFO( "Running dropdb with SQL file $dropdb_sql" );
        run( $config, 'sqlplus', connect_id( $config, 'dest_database' ), '@'.$dropdb_sql );
    }

    if ( $config->{import} ) {
        my $impdp_par  = generate_parfile( $config, $params, 'impdp_param' );
        INFO( "Running impdp with parameter file $impdp_par" );
        run( $config, 'impdp', connect_id( $config, 'dest_database' ), "parfile=$impdp_par" );
    }

    if ( $config->{sync_sequences} ) {
        INFO( "Synchronising sequence values" );
        sync_sequences( $config, $schema_name );
    }    
}

sub run {
    my ( $config, $cmd_name, @args ) = @_;

    my $cmd = $config->{$cmd_name}
        or die "Command $cmd_name not configured\n";

    if ( $config->{dryrun} ) {
        print 'Dry-run, would run: ' . join( q{ }, $cmd, @args ) . "\n";
        return;
    }

    systemx( $cmd, @args );
}

sub connect_id {
    my ( $config, $database ) = @_;

    sprintf( '%s/%s@%s', @{$config}{ 'dpump_user', 'password', $database } );
}

sub generate_sqlfile {
    my ( $config, $schema_name ) = @_;

    $schema_name = uc $schema_name;
    
    DEBUG( "Generating SQL to drop schema $schema_name" );

    my $tmp = File::Temp->new( SUFFIX => '.sql', UNLINK => $config->{unlink} );

    ( my $sql = $DROP_DATABASE_PLSQL ) =~ s/:schema/$schema_name/g;
    
    $tmp->print( $sql );

    return $tmp;    
}

sub generate_parfile {
    my ( $config, $params, $wanted ) = @_;

    DEBUG( "Generating $wanted parfile" );
    
    my @keys = map { force_array( $_ ) } @{$config}{ 'common_param', $wanted };

    my $tmp = File::Temp->new( UNLINK => $config->{unlink} );
    
    for my $p ( @keys ) {
        next unless defined $params->{$p};        
        for my $v ( force_array( $params->{$p} ) ) {
            my $param_string = join '=', $p, $v;
            DEBUG( '> ' . $param_string );
            $tmp->print( "$param_string\n" );
        }
    }

    $tmp->close;
    
    return $tmp;
}

sub data_pump_params {
    my ( $config, $schema_name ) = @_;

    my $params = $config->{schema}{$schema_name};
    $params->{flashback_time} = sprintf( "TO_TIMESTAMP('%s %s','YYYY-MM-DD HH24:MI:SS'",
                                         $config->{effective_date}->ymd,
                                         $config->{effective_date}->hms );

    return $params;
}

sub force_array {
    my $scalar_or_arrayref = shift;

    if ( not defined $scalar_or_arrayref ) {
        return;        
    }   
    elsif ( ref $scalar_or_arrayref eq 'ARRAY' ) {
        return @{$scalar_or_arrayref};
    }
    else {
        return ( $scalar_or_arrayref );
    }    
}

sub ensure_valid_schema {
    my ( $config, $schema_name ) = @_;

    die "Schema $schema_name not configured\n"
        unless $config->{schema}->{$schema_name};

    return $schema_name;
}

sub read_config {
    my $conffile = shift;

    DEBUG( "Reading configuration from $conffile" );
    
    my $conf = Config::General->new(
        -ConfigFile      => $conffile,
        -InterPolateVars => 1
    );

    my %config = $conf->getall;

    my @missing = grep { not defined $config{$_} } @REQUIRED_CONFIG_PARAMS;
    if ( @missing ) {
        die 'Configuration missing required ' . PL_N( 'parameter', scalar @missing )
            . ': ' . join( q{, }, @missing ) . "\n";
    }
    
    return \%config;
}

sub sync_sequences {
    my ( $config, $schema_name ) = @_;

    $schema_name = uc $schema_name;
    
    my $src_dbh  = dbi_connect( $config, 'src_database' );
    my $dest_dbh = dbi_connect( $config, 'dest_database' );

    ( my $select_sequences_query = sprintf $SELECT_SEQUENCES_SQL, $src_dbh->quote( $schema_name ) ) =~ s/\s+/ /g;
    DEBUG( "Preparing query: $select_sequences_query" );
    my $src_sequences = $src_dbh->prepare( $select_sequences_query );
    $src_sequences->execute();

    while ( my $src_seq = $src_sequences->fetchrow_hashref ) {
        my $identifier = $dest_dbh->quote_identifier( undef, $schema_name, $src_seq->{sequence_name} );
        try {
            ( my $select_curval_query = sprintf $SELECT_CURVAL_SQL, $identifier ) =~ s/\s+/ /g;
            DEBUG( "Running query: $select_curval_query" );
            my ( $dest_value ) = $dest_dbh->selectrow_array( $select_curval_query );
            if ( $dest_value < $src_seq->{last_number} ) {
                drop_sequence( $config, $dest_dbh, $identifier, $src_seq );
                create_sequence( $config, $dest_dbh, $identifier, $src_seq );
            }
        }
        catch {
            if ( $_ =~ m/sequence does not exist/ ) {
                create_sequence( $config, $dest_dbh, $identifier, $src_seq );
            }
            else {
                die "$_\n";
            }
        };
    }
}

sub dbi_connect {
    my ( $config, $db ) = @_;

    my $dsn = sprintf( 'dbi:Oracle:%s', $config->{$db} =~ m/(^[^.]+)/ );

    my $dbh = DBI->connect( $dsn, $config->{dpump_user}, $config->{password},
                            { RaiseError => 1, PrintError => 0, AutoCommit => 1 } )
        or die $DBI::errstr;

    $dbh->{FetchHashKeyName} = 'NAME_lc';
    
    return $dbh;
}

sub drop_sequence {
    my ( $config, $dbh, $identifier, $src_seq ) = @_;

    INFO( "Dropping sequence $identifier" );

    ( my $drop_sequence_query = sprintf $DROP_SEQUENCE_SQL, $identifier ) =~ s/\s+/ /g;

    if ( $config->{dryrun} ) {
        INFO( "Dry-run: would run query: $drop_sequence_query" );
        return;
    }
    
    DEBUG( "Running query: $drop_sequence_query" );
    $dbh->do( $drop_sequence_query );
}

sub create_sequence {
    my ( $config, $dbh, $identifier, $src_seq ) = @_;

    INFO( "Creating sequence $identifier with start value $src_seq->{last_number}" );
    
    my $cache = $src_seq->{cache_size} ? sprintf( 'CACHE %ld', $src_seq->{cache_size} )
              :                          'NOCACHE';
    my $order = $src_seq->{order_flag} eq 'Y' ? 'ORDER' : 'NOORDER';
    my $cycle = $src_seq->{cycle_flag} eq 'Y' ? 'CYCLE' : 'NOCYCLE';

    ( my $create_sequence_query = sprintf $CREATE_SEQUENCE_SQL, $identifier,
                                          @{$src_seq}{ qw( min_value max_value increment_by last_number ) },
                                          $cache, $order, $cycle ) =~ s/\s+/ /g;

    if ( $config->{dryrun} ) {
        INFO( "Dry-run: would run query: $create_sequence_query" );
        return;
    }
    
    DEBUG( "Running query: $create_sequence_query" );
    $dbh->do( $create_sequence_query );
}

__END__

=head1 NAME

data_pump.pl - Describe the usage of script briefly

=head1 SYNOPSIS

data_pump.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for data_pump.pl, 

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
