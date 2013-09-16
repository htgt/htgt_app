#!/usr/bin/env perl

use strict;
use Getopt::Long;
use Data::Dumper;
use HTGT::DBFactory;
use DateTime;

my $debug;
my $verbose;
my $updatedb;
my $help;
my $well_summary;
my $well_summary_by_di;

my $createProjects;
my $latest_status;
my $final_status;
my $adjust_alleles; 
my $transfer_kermits;
my $debug_subset = "";
my $project_subset = "";
my $final_status_subset = "";

GetOptions(
    'debug|d'                            => \$debug,
    'verbose|v'                          => \$verbose,
    'updatedb|u'                         => \$updatedb,
    'debug_subset:s'                     => \$debug_subset,
    'project_subset:s'                     => \$project_subset,
    'final_status_subset:s'                     => \$final_status_subset,
    'create_projects|cp'                 => \$createProjects,
    'mark_latest_status|mls'             => \$latest_status,
    'adjust_final_project_statuses|afps' => \$final_status,
    'adjust_mig_allele_requests|amar'    => \$adjust_alleles,    
    'transfer_kermits|tk'                => \$transfer_kermits,
    'help|?'                             => \$help,
    'well_summary=s'                     => \$well_summary,
    'well_summary_by_di=s'               => \$well_summary_by_di,
);

## Catch calls for help!

if ( $help || ( defined $ARGV[0] && $ARGV[0] =~ /\?|help/ ) ) {
    show_help();
    exit;
}

die "well_summary table name not specified" unless defined $well_summary;
die "well_summary_by_di table name not specified" unless defined $well_summary_by_di;

## Connect to the database...

my $schema = HTGT::DBFactory->connect( 'eucomm_vector' ); 

my ( $project_status_dict, $project_status_dict_by_id ) = get_project_status_dict();

if ( $createProjects ) {
  ##
  ## Get all projects IMPLIED by what we see in the pipeline
  ##
  print "Getting the pipeline projects by di with filter clause: $debug_subset\n";
  my $pipeline_projects = get_pipeline_projects_by_di_cassette_backbone($debug_subset);
  print "\nNumber of distinct design-instances for pipeline projects: " . scalar( keys %$pipeline_projects ) . "\n" if $verbose;
  print "\nCreating project entries...\n" if $verbose;
  create_projects( $pipeline_projects, $schema );
}

# 2. adjust the final project statuses
if ( $final_status ) { 
    print "Adjust the final project status\n";
    adjust_final_project_statuses( $schema, $final_status_subset );
}


# 3.  For all projects mark latest status - this does all projects automagically
if ( $latest_status ) { 
    print "Mark the latest status\n";
    mark_latest_status_for_project( $schema , $project_subset) 
}

exit;

######################################################
##                                                  ##
## Subroutines                                      ##
##                                                  ##
######################################################
    
sub get_project_id_for_clone {
    my $sth = $schema->storage->dbh->prepare_cached( "select project_id from ${well_summary_by_di} where epd_well_name = ?");
    $sth->execute( shift );
    if ( my $row = $sth->fetchrow_arrayref() ) {
        $sth->finish;
        return $row->[0];
    }
    return;
}

# Runs the is latest for project foreach of the filters ~ eucomm, norcom, komp, regeneron
sub mark_latest_status_for_project {
    my ( $schema, $debug_subset ) = @_;
    
    $debug_subset = "" unless $debug_subset; #make an empty string unless the user subsets for particular projects

    my @filters = ( ' and is_eucomm = 1 ', ' and is_komp_csd = 1 ', ' and is_norcomm = 1 ',  ' and is_komp_regeneron = 1 ', ' and is_eutracc = 1 ', ' and is_eucomm_tools = 1 ' );
    print "update_project_status - running mark latest project\n";
    
    for my $filter ( @filters ) {    
        my $project_sql = "
            select mgi_gene_id, project_status.order_by, project.project_id, project_status.project_status_id
            from project, project_status
            where project.project_status_id = project_status.project_status_id
            $filter
            $debug_subset
            order by order_by
        ";
        if ($verbose) { print "$project_sql\n"; }
        my $sth = $schema->storage->dbh->prepare($project_sql);
        $sth->execute();
        
        my $projects_by_gene;

        #Fetch project 'stubs' - NOT actual DBIxClass projects -- as arrayrefs indexed by mgi_gene_id 
        while ( my @result = $sth->fetchrow_array ) {

            my ( $mgi_gene_id, $order_by, $project_id, $project_status_id ) = @result;

            if ($debug) { print "read project $project_id with status $project_status_id\n"; }

            push @{ $projects_by_gene->{$mgi_gene_id} },
              {
                mgi_gene_id       => $mgi_gene_id,
                order_by          => $order_by,
                project_id        => $project_id,
                project_status_id => ${project_status_id}
              };
        }
        
        $schema->txn_do(
            sub {
                foreach my $mgi_gene_id ( keys %$projects_by_gene ) {
                    my @projects_for_gene = sort { ( $b->{order_by} <=> $a->{order_by} ) || ( $b->{project_id} <=> $a->{project_id} ) } @{ $projects_by_gene->{$mgi_gene_id} };
                    my $first = 1;
                    foreach my $project_ref (@projects_for_gene) {
                        if ( scalar(@projects_for_gene) == 1 ) {
                            my $project = $schema->resultset('Project')->find( $project_ref->{project_id} );
                            $project->is_latest_for_gene(1);
                            $project->update;
                        }
                        else {
                            my $project = $schema->resultset('Project')->find( $project_ref->{project_id} );
                            
                            #If the project status is one of the 'terminated' statuses then it won't be marked as 'lastest' unless it's the ONLY project
                            # for that gene.
                            if ( $project->status->does_not_compete_for_latest() ) {
                                print " skipping " . $project->project_id . " since it doesn't compete\n" if ($verbose);
                                if($updatedb){
                                    $project->is_latest_for_gene(0);
                                    $project->update;
                                }
                                next;
                            }
                            if ($first) {
                                print " setting " . $project->project_id . " to current\n" if ($verbose);
                                if($updatedb){
                                    $project->is_latest_for_gene(1);
                                }
                                $first = 0;
                            }
                            else {
                                print " setting " . $project->project_id . " to off\n" if ($verbose);
                                if($updatedb){
                                    $project->is_latest_for_gene(0);
                                }
                            }
                            if($updatedb){
                                $project->update;
                            }
                        }
                    }
                }
            }
        );        
    }
    print "update_project_status - finished running mark latest project\n";
}

# Runs the project status adjustment.
sub adjust_final_project_statuses {
    my ( $schema, $debug_subset ) = @_;
    print "update_project_status - running update final project statuses\n";
    
    $schema->txn_do(
        sub {
            my $projects_with_eps = _get_all_projects_with_eps( $schema, $debug_subset );
            print "number of electroporated : ".scalar( keys %$projects_with_eps ) . "\n";
            
            PROJECT:
            foreach my $project_with_ep_id ( keys %$projects_with_eps ) {
                my $project = $schema->resultset('HTGTDB::Project')->find($project_with_ep_id);
                if($project->status->is_terminal){
                    print "skipping terminal project: ".$project->project_id."\n";
                    next PROJECT;
                }
                if(!$project){ die "cant find project for id $project_with_ep_id"};
                if ( $project->status->order_by < 80 ) {
                    print "updating project  " . $project->project_id . " id with status: " . $project->status->name . " to EP In progress\n";
                    if ($updatedb) {
                        my $dt   = DateTime->now;
                        my $date = $dt->day . '-' . $dt->month_name . '-' . $dt->year;
                        $project->update({project_status_id=>16, edit_user=>'cronscript', edit_date=>$date});
                    }
                }
            }

            my $all_unpicked_projects_with_eps = _get_all_unpicked_projects_with_eps( $schema, $debug_subset );
            print "number of electroporated projects with zero picked: ".scalar( keys %$all_unpicked_projects_with_eps ) . "\n";
            PROJECT:
            foreach my $unpicked_project_id ( keys %$all_unpicked_projects_with_eps ) {
                my $project = $schema->resultset('HTGTDB::Project')->find($unpicked_project_id);
                if($project->status->is_terminal){
                    print "skipping terminal project: ".$project->project_id."\n";
                    next PROJECT;
                }
                if ( $project->status->order_by < 82 ) {
                    print "update project  " . $project->project_id . " id with status: " . $project->status->name . " to EP Unsuccessful\n";
                    if ($updatedb) {
                        my $dt   = DateTime->now;
                        my $date = $dt->day . '-' . $dt->month_name . '-' . $dt->year;
                        $project->update({project_status_id=>50, edit_user=>'cronscript', edit_date=>$date});
                    }
                }
            }

            my $all_genotyped_project_ids = _get_all_genotyped_project_ids( $schema, $debug_subset );
            print "number of genotyped projects: " . scalar( keys %$all_genotyped_project_ids ) . "\n";
            my $epd_dist_project_ids = _get_epd_dist_project_ids( $schema, $debug_subset );
            print "number of distributable projects: " . scalar( keys %$epd_dist_project_ids ) . "\n";

            foreach my $epd_dist_project_id ( keys %$epd_dist_project_ids ) {
                if ( exists $all_genotyped_project_ids->{$epd_dist_project_id} ) {
                    delete $all_genotyped_project_ids->{$epd_dist_project_id};
                } else {
                    warn "cant find $epd_dist_project_id in the already genotyped set\n";
                }
            }
            print "number of genotyped projects without a distributable es cell:" . scalar( keys %$all_genotyped_project_ids ) . "\n";

            foreach my $no_qc_pos_project_id ( keys %$all_genotyped_project_ids ) {
                my $project = $schema->resultset('HTGTDB::Project')->find($no_qc_pos_project_id);
                if ( $project->status->order_by < 85 ) {
                    print "updating project " . $project->project_id . " with status: " . $project->status->name . " to No QC Pos\n";
                    if ($updatedb) {
                        my $dt   = DateTime->now;
                        my $date = $dt->day . '-' . $dt->month_name . '-' . $dt->year;
                        $project->update({project_status_id=>17, edit_user=>'cronscript', edit_date=>$date});
                    }
                }
            }
        }
    );
    print "update_project_status - finished running update final project statuses\n";
}

sub _get_all_projects_with_eps {
    my $schema = shift;
    my $debug_subset = shift;
    my $return_ref;
    my $sql = qq[
            select distinct project_id
            from ${well_summary_by_di}
            where ep_well_name is not null and project_id is not null
            $debug_subset
        ];

    my $sth = $schema->storage->dbh->prepare($sql);
    $sth->execute();
    while ( my @result = $sth->fetchrow_array ) {
        $return_ref->{ $result[0] } = 1;
    }
    
    return $return_ref;
}

sub _get_all_unpicked_projects_with_eps {
    my $schema = shift;
    my $debug_subset = shift;
    my $return_ref;
    my $sql = qq[
        select distinct project_id
        from ${well_summary_by_di}
        where ep_well_name is not null and project_id is not null
        and (colonies_picked = 0 or colonies_picked is null)
        $debug_subset
      ];
    
    my $sth = $schema->storage->dbh->prepare($sql);
    $sth->execute();
    while ( my @result = $sth->fetchrow_array ) {
        $return_ref->{ $result[0] } = 1;
    }
    
    return $return_ref;
}

sub _get_all_genotyped_project_ids {
    my $schema = shift;
    my $debug_subset = shift;
    my $return_ref;
    my $sql = qq[
        select distinct project_id
        from ${well_summary_by_di}
        where epd_well_name is not null
        and project_id is not null
        $debug_subset
      ];
    
    my $sth = $schema->storage->dbh->prepare($sql);
    $sth->execute();
    while ( my @result = $sth->fetchrow_array ) {
        $return_ref->{ $result[0] } = 1;
    }

    return $return_ref;
}

sub _get_epd_dist_project_ids {
    my $schema = shift;
    my $debug_subset = shift;
    my $return_ref;
    my $sql = qq[
        select distinct project_id
        from ${well_summary_by_di}
        where
        epd_well_name is not null
        and ((${well_summary_by_di}.epd_distribute = 'yes') or (${well_summary_by_di}.targeted_trap = 'yes'))
        and project_id is not null
        $debug_subset
      ];
    
    my $sth = $schema->storage->dbh->prepare($sql);
    $sth->execute();
    while ( my @result = $sth->fetchrow_array ) {$return_ref->{ $result[0] } = 1 }
    return $return_ref;
}

sub show_help {
    print "\n";
    print qq(
        set_vector_distribute.pl [options]

        Options:
            -d -debug        debug mode (LOTS of output)
            -v -verbose      verbose mode (lets you know what's going on)
            -? -help         display this help and exit
            -u -updatedb     commit changes to database
            -p -production   connect to migp_ha (default is migt)
            
            -cp   -create_projects (creates/updates projects)
            -mls  -mark_latest_status             
            -afps -adjust_final_project_statuses
            -amar -adjust_mig_allele_requests
            -tk   -transfer_kermits
    );
    print "\n\n";
}

sub get_pipeline_projects_by_di_cassette_backbone{
    ##
    ## First get all well_summary rows by mig_gene_id
    ## For each set of rows for a mig-gene-id,
    ## Bundle into groups with disinct design_plate/well/cassette/backbone
    ## Inside each group, choose the most advanced passing pcs and pgd plate (if they exist)
    ## Make each group a distinct project. Stamp on PCS / PGD plates as appropriate.
    ##

    my ($subset) = @_;

    my $projects_by_di;
    my $rows_by_di_cassette_backbone;
    
    if($verbose){
        print "fetching cases where epd-di changes\n";
    }
    
    my $results_by_allele_key = {};
    my $pgg_based_ep_results = {};
    my $results_by_allele_key = get_alleles_with_altered_final_epd_di( $schema );
    my $pgg_based_ep_results = get_alleles_for_pgg_plates ( $schema );
    
    #my $pgg_based_ep_results = {};
    #my $results_by_allele_key = {};
    
    my $sql = qq[
        select 
            design_instance.design_id,
            ${well_summary}.design_instance_id,
            ${well_summary}.design_plate_name, 
            ${well_summary}.design_well_name, 
            ${well_summary}.design_instance_id, 
            ${well_summary}.bac,
            ${well_summary}.PCS_PLATE_NAME,
            ${well_summary}.PCS_WELL_NAME,
            ${well_summary}.PC_PASS_LEVEL,
            ${well_summary}.PCS_WELL_ID,
            ${well_summary}.PGDGR_WELL_ID,
            pcs_distribute,
            ${well_summary}.PGDGR_PLATE_NAME,
            ${well_summary}.PGDGR_WELL_NAME,
            ${well_summary}.CASSETTE,
            ${well_summary}.BACKBONE,
            ${well_summary}.PG_PASS_LEVEL,
            pgdgr_distribute,
            sum( total_colonies ) total_colonies,
            sum( colonies_picked ) colonies_picked,
            sum( decode( epd_distribute, null, 0, 'yes', 1 )) epd_distribute,
            sum( decode( targeted_trap, null, 0, 'yes', 1 )) targeted_trap,
            (select count ( distinct( child_well.well_id))
              from well child_well
              where 
              child_well.parent_well_id = ${well_summary}.PGDGR_WELL_ID
            ) child_well_count
        from 
            design_instance,
            ${well_summary}
        where
            design_instance.design_instance_id = ${well_summary}.design_instance_id
            and design_plate_name is not null 
            and design_well_name is not null
            $subset
        group by 
            design_instance.design_id,
            ${well_summary}.gene_id,
            ${well_summary}.design_instance_id,
            ${well_summary}.design_plate_name, 
            ${well_summary}.design_well_name, 
            ${well_summary}.design_instance_id, 
            ${well_summary}.bac,
            ${well_summary}.PCS_PLATE_NAME,
            ${well_summary}.PCS_WELL_NAME,
            ${well_summary}.PC_PASS_LEVEL,
            ${well_summary}.PCS_WELL_ID,
            ${well_summary}.PGDGR_WELL_ID,
            pcs_distribute,
            ${well_summary}.PGDGR_PLATE_NAME,
            ${well_summary}.PGDGR_WELL_NAME,
            ${well_summary}.CASSETTE,
            ${well_summary}.BACKBONE,
            ${well_summary}.PG_PASS_LEVEL,
            pgdgr_distribute
        order by 
            ${well_summary}.design_plate_name, 
            ${well_summary}.design_well_name, 
            ${well_summary}.PCS_PLATE_NAME,
            ${well_summary}.PCS_WELL_NAME,
            ${well_summary}.PGDGR_PLATE_NAME,
            ${well_summary}.PGDGR_WELL_NAME
    ];

    # gather all the possible projects - distinct design/cassette/backbone rows
    if($debug){
      print "$sql\n";
    }
    my $sth = $schema->storage->dbh->prepare($sql);
    $sth->execute();

    # accumulate all possible well-summary rows by di and cassette / backbone.
    while ( my $result = $sth->fetchrow_hashref ) {
        my $di_id    = $result->{DESIGN_INSTANCE_ID};
        my $cassette = $result->{CASSETTE};
        my $backbone = $result->{BACKBONE};
        my $cb_key;

        if   ( $cassette && $backbone ) { $cb_key = "${cassette}::${backbone}"; }
        else                            { $cb_key = "none"; }

        print STDERR "[debug] Adding row di/cass/backbone: $di_id:$cassette:$backbone:($cb_key)\n" if $debug;
        push @{ $rows_by_di_cassette_backbone->{$di_id}->{$cb_key} }, $result;
    }

    foreach my $di ( keys %{ $rows_by_di_cassette_backbone } ) {

        my @cb_keys = keys %{ $rows_by_di_cassette_backbone->{$di} };

        if ( scalar(@cb_keys) == 1 ) {

           print STDERR "[debug] Making project hash from single di/cass/backbone\n" if $debug;
            my $cb_key  = $cb_keys[0];
            my $rows    = $rows_by_di_cassette_backbone->{$di}->{$cb_key};
            my $project = make_project_hash_from_rows( $di, $cb_key, $rows, $results_by_allele_key, $pgg_based_ep_results );
            push @{ $projects_by_di->{$di}->{pipeline_projects} }, $project;

        } else {

            print STDERR "[debug] Making project hash from multiple di/cass/backbone: $di: @cb_keys \n" if $debug;
            foreach my $cb_key (@cb_keys) {
                if ( $cb_key eq 'none' ) {
                    next;
                } else {
                    my $rows = $rows_by_di_cassette_backbone->{$di}->{$cb_key};
                    my $project = make_project_hash_from_rows( $di, $cb_key, $rows, $results_by_allele_key, $pgg_based_ep_results );
                    push @{ $projects_by_di->{$di}->{pipeline_projects} }, $project;
                }
            }
        }
    }

    print "projects by di hashref: ".Data::Dumper->Dump([$projects_by_di])."\n" if $debug;
    return $projects_by_di;
}

sub make_project_hash_from_rows {
    my ( $design_instance_id, $cb_key, $rows, $results_by_allele_key, $pgg_based_ep_results) = @_;
    
    #print STDERR "making project hash from $design_instance_id $cb_key and ".scalar(@$rows)." well summary rows \n";

    my $bac;
    my $cassette;
    my $backbone;
    my $intermediate_vector_id;
    my $targeting_vector_id;
    my $intvec_plate_name;
    my $intvec_well_name;
    my $targvec_plate_name;
    my $targvec_well_name;
    my $targvec_distribute;
    my $total_colonies;
    my $colonies_picked;
    my $epd_distribute;
    my $targeted_trap;
    my $pc_pass_level;
    my $pg_pass_level;

    if ( ( $cb_key =~ /(\S+)::(\S+)/ ) ) {
        $cassette = $1;
        $backbone = $2;
    } elsif ( $cb_key eq 'none' ) {

        #$cassette = 'none';
        #$backbone = 'none';
        # Do nothing - the above fucks with the status logic later on!!!! >:-(
    } else {
        die "[error] Can't make sense of key: $cb_key";
    }

    # what we have to produce after the loop is done

    if ($debug) {
        print "choosing pc and pg rows for di: $design_instance_id and c/b: $cb_key\n";
    }
    
    my ( $design_id, $design_plate_name, $design_well_name, $chosen_pc_row, $chosen_pg_row )
      = choose_pc_and_pg_vectors_from_possible_rows_for_di_and_backbone($rows, $results_by_allele_key, $pgg_based_ep_results);

    if ($debug) {
        print "got design: $design_id with plate and well name $design_plate_name, $design_well_name afterwards\n";
    }

    if($debug){
        if(defined $chosen_pc_row){
            print STDERR "chosen pc row: ".Data::Dumper->Dump([$chosen_pc_row])."\n" ;
        }else{
            print STDERR "chosen pc row not defined\n" ;
        }
        
        if(defined $chosen_pg_row){
            print STDERR "chosen pg row: ".Data::Dumper->Dump([$chosen_pg_row])."\n";
        }else{
            print STDERR "chosen pg row not defined\n";
        }
    }
    
    if (defined $chosen_pc_row) {
        print "overwriting with chosen pc row\n" if $debug;
        
        $design_id              = $chosen_pc_row->{DESIGN_ID};
        $design_plate_name      = $chosen_pc_row->{DESIGN_PLATE_NAME};
        $design_well_name       = $chosen_pc_row->{DESIGN_WELL_NAME};
        $intermediate_vector_id = $chosen_pc_row->{PCS_WELL_ID};
        $intvec_plate_name      = $chosen_pc_row->{PCS_PLATE_NAME};
        $intvec_well_name       = $chosen_pc_row->{PCS_WELL_NAME};
        $pc_pass_level          = $chosen_pg_row->{PC_PASS_LEVEL};
    }

    my $epd_recovered       = undef;
        
    if (defined $chosen_pg_row) {
        print "overwriting with chosen pg row\n" if $debug;
        $design_id           = $chosen_pg_row->{DESIGN_ID};
        $design_plate_name   = $chosen_pg_row->{DESIGN_PLATE_NAME};
        $design_well_name    = $chosen_pg_row->{DESIGN_WELL_NAME};
        $bac                 = $chosen_pg_row->{BAC};
        $pg_pass_level       = $chosen_pg_row->{PG_PASS_LEVEL};
        $targeting_vector_id = $chosen_pg_row->{PGDGR_WELL_ID};
        $targvec_plate_name  = $chosen_pg_row->{PGDGR_PLATE_NAME};
        $targvec_well_name   = $chosen_pg_row->{PGDGR_WELL_NAME};
        $targvec_distribute  = $chosen_pg_row->{PGDGR_DISTRIBUTE};
        
        my $allele_key = "${design_instance_id}::${cassette}::${backbone}";
        #if($debug && ($allele_key eq ('102182::L1L2_Bact_P::L4L3_pD223_DTA_spec'))){
        #    print "checking for allele $allele_key\n";
        #    print Data::Dumper->Dump([$results_by_allele_key->{$allele_key}]);
        #}
        
        # See if we can replace the epd-results by a group of known cases where Tony has changed
        # the epd-design-instance at the epd step
        if(defined $results_by_allele_key->{$allele_key}){
            
            if($verbose || $debug){ print "replacing epd results for vector $allele_key with tronly-derived results\n"; }
            $total_colonies      = $results_by_allele_key->{$allele_key}->{total_colonies};
            $colonies_picked     = $results_by_allele_key->{$allele_key}->{colonies_picked};
            $epd_distribute      = $results_by_allele_key->{$allele_key}->{epd_distribute};
            $targeted_trap       = $results_by_allele_key->{$allele_key}->{targeted_trap};
            $epd_recovered       = 1;
        
        } elsif ( defined $pgg_based_ep_results->{$targeting_vector_id} ){
            
            # See if we can replace the epd-results by a group of known cases where the new
            # pgg plates have caused a break in the well-summary report. 
            if($verbose || $debug){
                print "replacing epd results for targeting_vector_id $targeting_vector_id with pgg-derived results\n";
                print "EPD distribute count for this replacement: ".$pgg_based_ep_results->{$targeting_vector_id}->{epd_distribute}."\n";
                if($debug){
                    print Data::Dumper->Dump([$pgg_based_ep_results->{$targeting_vector_id}])."\n";
                }
            }
            $total_colonies      = $pgg_based_ep_results->{$targeting_vector_id}->{total_colonies};
            $colonies_picked     = $pgg_based_ep_results->{$targeting_vector_id}->{colonies_picked};
            $epd_distribute      = $pgg_based_ep_results->{$targeting_vector_id}->{epd_distribute};
            $targeted_trap       = $pgg_based_ep_results->{$targeting_vector_id}->{targeted_trap};
            $epd_recovered       = 1;
            
        }else{
            
            if($debug){ print "NOT replacing epd results for vector $allele_key ($targeting_vector_id) with either tronly-derived or pgg-results\n"; }
            $total_colonies      = $chosen_pg_row->{TOTAL_COLONIES};
            $colonies_picked     = $chosen_pg_row->{COLONIES_PICKED};
            $epd_distribute      = $chosen_pg_row->{EPD_DISTRIBUTE};
            $targeted_trap       = $chosen_pg_row->{TARGETED_TRAP};
            
        }
    }
    
    if($verbose && $epd_recovered){
        print " project $design_instance_id :: $cassette :: $backbone has epd_recover $epd_recovered\n";
    }

    print "making project hash with design plate / well: $design_plate_name, $design_well_name\n" if $debug;
    
    my $project = {
        design_id              => $design_id,
        design_instance_id     => $design_instance_id,
        design_plate_name      => $design_plate_name,
        design_well_name       => $design_well_name,
        cassette               => $cassette,
        backbone               => $backbone,
        intermediate_vector_id => $intermediate_vector_id,
        intvec_plate_name      => $intvec_plate_name,
        intvec_well_name       => $intvec_well_name,
        pc_pass_level          => $pc_pass_level,
        targvec_plate_name     => $targvec_plate_name,
        targvec_well_name      => $targvec_well_name,
        pg_pass_level          => $pg_pass_level,
        targeting_vector_id    => $targeting_vector_id,
        targvec_distribute     => $targvec_distribute,
        total_colonies         => $total_colonies,
        colonies_picked        => $colonies_picked,
        epd_distribute         => $epd_distribute,
        targeted_trap          => $targeted_trap,
        bac                    => $bac,
        epd_recovered          => $epd_recovered
    };
    
    if($debug){
        print "returning project\n";
        print Data::Dumper->Dump([$project]);
    }

    return $project;
}

sub choose_pc_and_pg_vectors_from_possible_rows_for_di_and_backbone {
    my $rows = shift;
    my $epd_di_changing_results_by_allele_key = shift;
    my $pgg_based_ep_results = shift;
    
    my @all_pc_rows;

    #crude way of keeping recovery separate (prioritised)
    my @all_tv_rows;
    my @all_pgs_rows;
    my @all_pgr_rows;
    my @all_htgrs_rows;
    my @all_grd_rows;
    my @all_gr_rows;

    my $chosen_pc_row;
    my $chosen_pg_row;
    my $design_id;
    my $design_plate_name;
    my $design_well_name;

    foreach my $row (@$rows) {

        $design_id         = $row->{DESIGN_ID};
        $design_plate_name = $row->{DESIGN_PLATE_NAME};
        $design_well_name  = $row->{DESIGN_WELL_NAME};

        if($debug){
            print "row from db: $design_id: $design_plate_name: $design_well_name\n";
            print "PCS: ".$row->{PCS_PLATE_NAME}.":".$row->{PCS_WELL_NAME}."\n";
            print "PGD: ".$row->{PGDGR_PLATE_NAME}.":".$row->{PGDGR_WELL_NAME}.":".$row->{CASSETTE}.":".$row->{BACKBONE}."\n";
            print "PGD: ".$row->{PGDGR_DISTRIBUTE}.":".$row->{CHILD_WELL_COUNT}."\n";
	    #print "check 1:".($row->{PGDGRP_PLATE_NAME} =~ /^PG0/)."\n";
	    #print "check 2:".$row->{PGDGR_DISTRIBUTE}."\n";
	    #print "check 3:".($row->{PGDGR_DISTRIBUTE} eq 'yes')."\n";
	    #print "check 4:".($row->{CHILD_WELL_COUNT})."\n";
	    #print "check 5:".($row->{CHILD_WELL_COUNT}>0)."\n";
	    #print "check 5:".($row->{EPD_DISTRIBUTE})."\n";
        }

        if($debug){
              print "looking for tv ".$row->{PGDGR_PLATE_NAME}."_".$row->{PGDGR_WELL_NAME}." with id: ".$row->{PGDGR_WELL_ID}."\n";
              my @tmp = sort {$a <=> $b} keys %{$pgg_based_ep_results};
              #print "What are these pgg vector ids in which we're looking ? @tmp\n";
              print Data::Dumper->Dump([$pgg_based_ep_results->{$row->{PGDGR_WELL_ID}}])."\n";
        }
        
        if ( $row->{PGDGR_PLATE_NAME} ) {
            
            my $allele_key = $row->{DESIGN_INSTANCE_ID}.":".$row->{CASSETTE}.":".$row->{BACKBONE};
            my $tv_id = $row->{PGDGR_WELL_ID};
            

            if (
                ($row->{EPD_DISTRIBUTE} && ( $row->{EPD_DISTRIBUTE} > 0 )) ||
                ($row->{TARGETED_TRAP} && ( $row->{TARGETED_TRAP} > 0 ))
            ) {
                
                if($verbose){
                    print "setting pass sort order of pg row ".$row->{PGDGR_PLATE_NAME}."_".$row->{PGDGR_WELL_NAME}." to 3 because of EPD distribute\n";
                }
                $row->{PASS_SORT_ORDER} = 3;
            
            }elsif (
                
                ( defined $pgg_based_ep_results->{$row->{PGDGR_WELL_ID}} ) &&
                ( $pgg_based_ep_results->{$row->{PGDGR_WELL_ID}}->{epd_distribute} > 0 )
            
            ) {
                
                if($verbose){
                    print "setting pass sort order of pg row ".$row->{PGDGR_PLATE_NAME}."_".$row->{PGDGR_WELL_NAME}." to 3 because of pgg-matched allele pass\n";
                }
                $row->{PASS_SORT_ORDER} = 3;
            
            }elsif (
                
                ( defined $epd_di_changing_results_by_allele_key->{$allele_key} ) &&
                ( $epd_di_changing_results_by_allele_key->{$allele_key}->{epd_distribute} > 0 )

            ) {
                
                if($verbose){
                    print "setting pass sort order of pg row ".$row->{PGDGR_PLATE_NAME}."_".$row->{PGDGR_WELL_NAME}." to 3 because of tronly-matched allele pass\n";
                }
                $row->{PASS_SORT_ORDER} = 3;
                
            } elsif ($row->{TOTAL_COLONIES} && ($row->{TOTAL_COLONIES}>0)) {
              
                if($verbose){
                    print "setting pass sort order of pg row ".$row->{PGDGR_PLATE_NAME}."_".$row->{PGDGR_WELL_NAME}." to 2.45 because it has EPd colonies\n";
                }
                $row->{PASS_SORT_ORDER} = 2.45;
            
            } elsif (
                ($row->{PGDGR_PLATE_NAME} =~ /^PG0/) && $row->{PGDGR_DISTRIBUTE} &&
                ( $row->{PGDGR_DISTRIBUTE} eq 'yes' ) && $row->{CHILD_WELL_COUNT} && ($row->{CHILD_WELL_COUNT}>0)
            ) {
              
                if($verbose){
                    print "setting pass sort order of pg row ".$row->{PGDGR_PLATE_NAME}."_".$row->{PGDGR_WELL_NAME}." to 2-2.8 because it's a 384-plate and it has child wells\n";
                }
                if(($row->{PG_PASS_LEVEL} =~ /pass1/) && ($row->{PG_PASS_LEVEL} !~ /b/)){
                    $row->{PASS_SORT_ORDER} = 2.8;
                }elsif(($row->{PG_PASS_LEVEL} =~ /pass2/) && ($row->{PG_PASS_LEVEL} !~ /b/)){
                    $row->{PASS_SORT_ORDER} = 2.7;
                }elsif(($row->{PG_PASS_LEVEL} =~ /pass3/) && ($row->{PG_PASS_LEVEL} !~ /b/)){
                    $row->{PASS_SORT_ORDER} = 2.6;
                }elsif(($row->{PG_PASS_LEVEL} =~ /pass4.1/) && ($row->{PG_PASS_LEVEL} !~ /b/)){
                    $row->{PASS_SORT_ORDER} = 2.5;
                }else{
                    $row->{PASS_SORT_ORDER} = 2;
                }
                
            }elsif (  ($row->{PGDGR_PLATE_NAME} !~ /^PG0/) && $row->{PGDGR_DISTRIBUTE} && ( $row->{PGDGR_DISTRIBUTE} eq 'yes' ) ) {
                if($verbose){
                    print "setting a NON-384 pass from 2.-2.4 ".$row->{PGDGR_PLATE_NAME}."_".$row->{PGDGR_WELL_NAME}."\n";
                }
                # For now, we only drop in here if the plate isn't like PG0
              
                if(($row->{PG_PASS_LEVEL} =~ /pass1/) && ($row->{PG_PASS_LEVEL} !~ /b/)){
                    $row->{PASS_SORT_ORDER} = 2.4;
                }elsif(($row->{PG_PASS_LEVEL} =~ /pass2/) && ($row->{PG_PASS_LEVEL} !~ /b/)){
                    $row->{PASS_SORT_ORDER} = 2.3;
                }elsif(($row->{PG_PASS_LEVEL} =~ /pass3/) && ($row->{PG_PASS_LEVEL} !~ /b/)){
                    $row->{PASS_SORT_ORDER} = 2.2;
                }elsif(($row->{PG_PASS_LEVEL} =~ /pass4.1/) && ($row->{PG_PASS_LEVEL} !~ /b/)){
                    $row->{PASS_SORT_ORDER} = 2.1;
                }else{
                    $row->{PASS_SORT_ORDER} = 2;
                }
                
            } else {
                
                $row->{PASS_SORT_ORDER} = 1;
                
            }

            # CRITICAL - only pay attention to the intermediate for this plate IF
            # it's resulted in a new targeting vector!! So Tony may build a new intermediate,
            # on the same recombineering product, but we will only consider it worth recording
            # when it's made a tv.
            if ( $row->{PCS_PLATE_NAME} ) { push @all_pc_rows, $row; }
            
            
            if ( $row->{PGDGR_PLATE_NAME} =~ /PGS/ ) {
                $row->{PLATE_SORT_ORDER} = 2;
                push @all_tv_rows, $row;
            } elsif ( $row->{PGDGR_PLATE_NAME} =~ /^PG/ ) {
                $row->{PLATE_SORT_ORDER} = 1;
                push @all_tv_rows, $row;
            } elsif ( $row->{PGDGR_PLATE_NAME} =~ /HTGRS/ ) {
                $row->{PLATE_SORT_ORDER} = 5;
                push @all_tv_rows, $row;
            } elsif ( $row->{PGDGR_PLATE_NAME} =~ /^HTGR/ ) {
                $row->{PLATE_SORT_ORDER} = 1;
                push @all_tv_rows, $row;
            } elsif ( $row->{PGDGR_PLATE_NAME} =~ /GRD/ ) {
                $row->{PLATE_SORT_ORDER} = 4;
                push @all_tv_rows, $row;
            } elsif ( $row->{PGDGR_PLATE_NAME} =~ /^GR/ ) {
                $row->{PLATE_SORT_ORDER} = 1;
                push @all_tv_rows, $row;
            } elsif ( $row->{PGDGR_PLATE_NAME} =~ /PGR/ ) {
                $row->{PLATE_SORT_ORDER} = 3;
                push @all_tv_rows, $row;
            } else {
                warn "I cant identify the nature of pgdgr plate " . $row->{PGDGR_PLATE_NAME} . "\n";
                next;
            }

            if ($debug) {
                print "tv : "
                  . $row->{PGDGR_PLATE_NAME} . ":"
                  . $row->{PGDGR_WELL_NAME}
                  . " has pass sort "
                  . $row->{PASS_SORT_ORDER}
                  . " and plate sort "
                  . $row->{PLATE_SORT_ORDER} . "\n";
            }
        }
    }

    # Sort all the epd-distributable vectors at high priority, then the good targeting vectors.
    # If we have a tie within those classes, then take vectors from the the HTGRS, PGR, GRD, PGS and GR plates in that order
    my @sorted_tv_rows = sort {
          ( $a->{PASS_SORT_ORDER} <=> $b->{PASS_SORT_ORDER} )
          || ( $a->{PLATE_SORT_ORDER} <=> $b->{PLATE_SORT_ORDER} )
    } @all_tv_rows;

    if ($debug) {
        print "total number of sorted vectors: " . scalar(@sorted_tv_rows) . "\n";

        #print "Size of sorted htgrs rows: ".scalar(@sorted_htgrs_rows)."\n";
        #print "Size of sorted grd rows: ".scalar(@sorted_grd_rows)."\n";
        #print "Size of sorted pgr rows: ".scalar(@sorted_pgr_rows)."\n";
        #print "Size of sorted pg rows: ".scalar(@sorted_pg_rows)."\n";
    }

    if ( scalar(@sorted_tv_rows) ) {
        $chosen_pg_row = pop @sorted_tv_rows;
        $chosen_pc_row = $chosen_pg_row;
    }

    if ($debug) {
        print "chose tv row: ".Data::Dumper->Dump([$chosen_pg_row])."\n";
    }

    if ($debug) {
        print "chose pc row: ".Data::Dumper->Dump([$chosen_pg_row])."\n";
    }

    return ( $design_id, $design_plate_name, $design_well_name, $chosen_pc_row, $chosen_pg_row );
}

sub get_project_status_dict {
    my $project_status_dict;
    my $project_status_dict_by_id;

    my $status_rs = $schema->resultset('ProjectStatus')->search( {} );

    while ( my $status = $status_rs->next ) {
        $project_status_dict->{ $status->code } = {
            project_status_id => $status->project_status_id,
            order_by          => $status->order_by,
            name              => $status->name
        };

        $project_status_dict_by_id->{ $status->project_status_id } = {
            project_status_id => $status->project_status_id,
            order_by          => $status->order_by,
            name              => $status->name
        };
    }

    return ( $project_status_dict, $project_status_dict_by_id );
}

sub create_projects{
    print "update_project_status - running create projects\n";
    
    my ( $pipeline_projects, $target_schema) = @_;
    my $counter = 0;
    print "number of dis ".scalar(keys %{$pipeline_projects})."\n";

    # START HERE START HERE - first pull the existing logic apart. You only have to rebuilt
    # The part which finds existing pipeline rows and rebuilds them
    $target_schema->txn_do(
        sub {
            DI:
            foreach my $di_id ( keys %{$pipeline_projects} ) {
                
                $counter++;
                print "\t >>> di count $counter, with number of dis: ".scalar(keys %{$pipeline_projects})."\n" if ($verbose);
                
                my @existing_projects = $target_schema->resultset('Project')->search(
                    { design_instance_id => $di_id }
                );
                
                if(! scalar(@existing_projects)){
                    my $design_instance = $schema->resultset('HTGTDB::DesignInstance')->find({design_instance_id=>$di_id});
                    my $design_id = $design_instance->design->design_id;
                    @existing_projects = $target_schema->resultset('Project')->search( { design_id => $design_id } );
                        
                    if(! scalar(@existing_projects)){
                        warn "we have $di_id in the pipeline without a corresponding project\n";
                        next;
                    }
                }
                
                my $sample_project = $existing_projects[0];
                my $design_id = $sample_project->design_id;
                my $existing_mgi_gene = $sample_project->mgi_gene;

                ##
                ## Now we work though each 'pipeline_project' entry and see if we're creating or updating an entry....
                ##
                PROJECT:
                foreach my $pipeline_project ( @{ $pipeline_projects->{$di_id}->{pipeline_projects} } ) {
                    
                    print "considering project for gene ".$existing_mgi_gene->mgi_gene_id."\n";

                    my $dt   = DateTime->now;
                    my $date = $dt->day . '-' . $dt->month_name . '-' . $dt->year;
                    my $new_project = {
                        project_status_id    => 11, # targeting vector in construction
                        mgi_gene_id          => $existing_mgi_gene->mgi_gene_id,
                        is_publicly_reported => 1,
                        is_komp_csd          => $sample_project->is_komp_csd,
                        is_komp_regeneron    => $sample_project->is_komp_regeneron,
                        is_eucomm            => $sample_project->is_eucomm,
                        is_norcomm           => $sample_project->is_norcomm,
                        is_mgp               => $sample_project->is_mgp,
                        edit_user              => 'cronscript',
                        edit_date            => $date,
                        design_id              => $pipeline_project->{design_id},
                        design_instance_id     => $pipeline_project->{design_instance_id},
                        design_plate_name      => $pipeline_project->{design_plate_name},
                        design_well_name       => $pipeline_project->{design_well_name},
                        bac                    => $pipeline_project->{bac},
                        cassette               => $pipeline_project->{cassette},
                        backbone               => $pipeline_project->{backbone},
                        intermediate_vector_id => $pipeline_project->{intermediate_vector_id},
                        intvec_plate_name      => $pipeline_project->{intvec_plate_name},
                        intvec_well_name       => $pipeline_project->{intvec_well_name},
                        intvec_pass_level      => $pipeline_project->{pc_pass_level},
                        targvec_plate_name     => $pipeline_project->{targvec_plate_name},
                        targvec_well_name      => $pipeline_project->{targvec_well_name},
                        targvec_pass_level     => $pipeline_project->{pg_pass_level},
                        targvec_distribute     => $pipeline_project->{targvec_distribute},
                        targeting_vector_id    => $pipeline_project->{targeting_vector_id},
                        total_colonies         => $pipeline_project->{total_colonies},
                        colonies_picked        => $pipeline_project->{colonies_picked},
                        epd_distribute         => $pipeline_project->{epd_distribute},
                        targeted_trap          => $pipeline_project->{targeted_trap}
                    };
                    

                    if ($debug) {
                        print "Created project hash for update: \n" . Dumper($new_project) . "\n";
                    }


                    if ($debug) {
                        print
                            "Looking for project by di/c/b:".$pipeline_project->{design_instance_id}." cassette / backbone ".
                            $pipeline_project->{cassette}.":".$pipeline_project->{backbone}."\n ";
                    }

                    ## See if there is a project entry already
                    my @current_projects = $target_schema->resultset('Project')->search(
                        {
                            design_instance_id => $pipeline_project->{design_instance_id},
                            cassette           => $pipeline_project->{cassette},
                            backbone           => $pipeline_project->{backbone}
                        }
                    );

                    my $current_project;

                    if (@current_projects) {
                        print "matched dicb: ".$pipeline_project->{design_plate_name}.":".$pipeline_project->{design_well_name}.":".$pipeline_project->{targvec_plate_name}.":".$pipeline_project->{design_instance_id}.":".$pipeline_project->{cassette}.":".$pipeline_project->{backbone}."\n" if $debug;
                        if ( scalar(@current_projects) == 1 ) {
                            $current_project = $current_projects[0];
                            if ($debug) {
                                print "found project with id ".$current_project->project_id."\n";
                            }
                        } else {
                            
                            # In the case where a komp vector is put into a eucomm ep, we deliberately hold two projects
                            # - in that case, we have to find the eucomm project (to update it correctly here).
                            my $eucomm_ep_project = get_eucomm_ep_project_from_multiples (\@current_projects);
                            if($eucomm_ep_project){
                                $current_project = $eucomm_ep_project;
                            }else{
                                warn "found more than one suitable project for di: " . $pipeline_project->{design_instance_id} . " cassette: "
                                  . $pipeline_project->{cassette} . " backbone " . $pipeline_project->{backbone} . " backbone " . "\n";
                                next;
                            }
                        }
                    }

                    ## If not, see if there is a gene + di placeholder to update from...
                    unless ($current_project) {
                        print "... Failed - Looking for project by di \n " if $debug;

                        my @current_projects = $target_schema->resultset('Project')->search(
                            {   
                                design_instance_id => $pipeline_project->{design_instance_id},
                                cassette => undef,
                                backbone => undef
                            },
                        );

                        if (@current_projects) {
                            print "matched dionly: ".$pipeline_project->{design_plate_name}.":".$pipeline_project->{design_well_name}.":".$pipeline_project->{targvec_plate_name}.":".$pipeline_project->{design_instance_id}.":".$pipeline_project->{cassette}.":".$pipeline_project->{backbone}."\n" if $debug;
                            if ( scalar(@current_projects) == 1 ) {
                                $current_project = $current_projects[0];
                            } else {
                                die "found more than one suitable project for di: " . $pipeline_project->{design_instance_id} . " and null cassette and backbone ";
                            }
                        }
                    }

                    ## If not, see if there is a project with the same design placeholder to update ...
                    unless ($current_project) {
                        print "... Failed - Looking for project by di \n " if $debug;

                        my @current_projects = $target_schema->resultset('Project')->search(
                            {   
                                design_id => $design_id,
                                design_instance_id => undef,
                                cassette => undef,
                                backbone => undef
                            },
                        );

                        if (@current_projects) {
                            print "matched design only: ".$pipeline_project->{design_id}."\n" if $debug;
                            if ( scalar(@current_projects) == 1 ) {
                                $current_project = $current_projects[0];
                            } else {
                                die "found more than one suitable project for di: " . $pipeline_project->{design_instance_id} . " and null cassette and backbone ";
                            }
                        }
                    }
                    
                    ##
                    ## Finally, see if we need to enter some data...
                    ##
                    if($current_project){
                        print "matched current project ".$current_project->project_id."\n";
                    }else{
                        print "no match to current project\n";
                    }
                    
                    if ($current_project) {
                        
                        # For a terminal status, once a project gets into this status, it will never leave (automatically)
                        # At time of writing, the terminal statuses are 'Withdrawn', 'Regeneron', and the TV-PT and TVU-PT statuses
                        if( $current_project->status->is_terminal ){ print "skipping terminal project ".$current_project->project_id."\n"; next PROJECT; }
                        
                        # This code won't alter mouse statuses altered by this code (they are set and reset later)
                        if ( $current_project->status->order_by > 95 ){ print "skipping mouse project ".$current_project->project_id."\n"; next PROJECT; }
    
                        # Make the project-status-id FIRST line up with the found project.
                        $new_project->{project_status_id} = $current_project->project_status_id;
                        # Now update it with the actual pipeline results.
                            
                        set_project_status_from_pipeline($new_project);
                        my $new_status = $project_status_dict_by_id->{ $new_project->{project_status_id} }->{name};

                        if(!($new_project->{project_status_id} eq $current_project->status->project_status_id)){
                            print
                                "status of current project:".$current_project->project_id.", new status: $new_status, current status: ".
                                ":(".$current_project->status->name."):". $pipeline_project->{design_plate_name}.":"
                                .$pipeline_project->{design_well_name}.":".$pipeline_project->{targvec_plate_name}."\n";
                        }else{
                            print "status of current project:".$current_project->project_id." unchanged ($new_status)\n"; 
                        }
                        
                        ## If yes, see if there is any difference to what we have now,
                        ## if there is no difference, don't update...
                        if ( do_i_update_project( $current_project, $new_project ) ) {
                            print
                                "UPDATE,".
                                $current_project->mgi_gene->marker_symbol.",".
                                $current_project->project_id.",".
                                $current_project->status->name.",$new_status,".
                                $current_project->design_plate_name.",".
                                $current_project->design_well_name.",".
                                $current_project->intvec_plate_name.",".
                                $current_project->intvec_well_name.",".
                                $current_project->targvec_plate_name.",".
                                $current_project->targvec_well_name.",".
                                $new_project->{design_plate_name}.",".
                                $new_project->{design_well_name}.",".
                                $new_project->{targvec_plate_name}.",".
                                $new_project->{targvec_well_name}.",".
                                $new_project->{cassette}.",".
                                $new_project->{backbone}.
                                "\n" if $verbose;
                                
                            if($debug){
                                print "update to new status: ".$new_project->{project_status_id}.", current project status: ".$current_project->status->project_status_id.":(".$current_project->status->name."):".$pipeline_project->{design_plate_name}.":".$pipeline_project->{design_well_name}.":".$pipeline_project->{targvec_plate_name}."\n";
                            }
                            if ($updatedb) {
                                # The update will over-ride whether the FOUND project is komp, eucomm etc. This is a bad thingespecially since
                                # there are now pairs of projects for the same di / c / b, one member of which is komp, and the other eucomm.
                                # In this case we dont want to overwrite the komp / eucomm marker of one project with another.
                                delete $new_project->{'is_komp_csd'};
                                delete $new_project->{'is_komp_regeneron'};
                                delete $new_project->{'is_eucomm'};
                                delete $new_project->{'is_norcomm'};
                                delete $new_project->{'is_mgp'};
                                $current_project->update($new_project);
                                print "[debug] Updated existing project " . $current_project->project_id . "\n" if $debug;
                            }
                            print "[debug] SHOULD updated existing project " . $current_project->project_id . "\n" if $debug;
                        } else {
                            
                            #If we just found this project new, then it will have project-status-id
                            # vector-construction-in-progress. NOW change that according to what we see in pipe
                            print
                                "SAME,".
                                $current_project->mgi_gene->marker_symbol.",".
                                $current_project->project_id.",".
                                $current_project->status->name.",$new_status,".
                                $current_project->design_plate_name.",".
                                $current_project->design_well_name.",".
                                $current_project->intvec_plate_name.",".
                                $current_project->intvec_well_name.",".
                                $current_project->targvec_plate_name.",".
                                $current_project->targvec_well_name.",".
                                $new_project->{design_plate_name}.",".
                                $new_project->{design_well_name}.",".
                                $new_project->{targvec_plate_name}.",".
                                $new_project->{targvec_well_name}.",".
                                $new_project->{cassette}.",".
                                $new_project->{backbone}.
                                "\n" if $verbose;
                            print "dont update - statuses: ".$new_project->{project_status_id}.", current project status: ".$current_project->status->project_status_id.":(".$current_project->status->name.")".$pipeline_project->{design_plate_name}.":".$pipeline_project->{design_well_name}.":".$pipeline_project->{targvec_plate_name}."\n" if $debug;
                            print "[debug] Did not update existing project " . $current_project->project_id . "\n" if $debug;
                        }
                    } else {
                        print "found new (unmatched) pipeline project\n";
                        set_project_status_from_pipeline($new_project);
                        my $new_status = $project_status_dict_by_id->{ $new_project->{project_status_id} }->{name};
                        print 
                            "NEW,".
                            $sample_project->mgi_gene->marker_symbol.",".
                            ",$new_status,".
                            $new_project->{mgi_gene_id}.",".
                            $new_project->{design_plate_name}.",".
                            $new_project->{design_well_name}.",".
                            ",".
                            ",".
                            ",".
                            ",".
                            $new_project->{targvec_well_name}.",".
                            $new_project->{cassette}.",".
                            $new_project->{backbone}.",".
                            "\n" if $verbose;
                        ## If no, create a new entry...
                        if ($updatedb) {
                            $current_project = $target_schema->resultset('Project')->create($new_project);
                            print "[debug] Created project " . ", project status: ".$current_project->status->project_status_id.":(".$current_project->status->name.")".$pipeline_project->{design_plate_name}.":".$pipeline_project->{design_well_name}.":".$pipeline_project->{targvec_plate_name}. "\n" if $verbose;
                        }
                    }
                }
            }
        }
    );
    print "update_project_status - finished running create projects\n";
}

sub set_project_status_from_pipeline {
    ##
    ## Function to set the status of a project entry based on
    ## its progress through the pipeline...
    ##

    my ($project) = @_;
    
    
    if ($debug) { print "overwriting project status based on pipeline info\n"; }
    

    # If we have distributable cells under any conditions, then set it and return.
    if (
      ($project->{epd_distribute} && ( $project->{epd_distribute} > 0 ))||
      ($project->{targeted_trap} && ( $project->{targeted_trap} > 0 ))
    ) {
        $project->{project_status_id} = $project_status_dict->{'ES-TC'}->{project_status_id};
        return;
    }
    
    # If the project was marked with no-qc-positives or ep unsuccessful, then leave it there for now.
    # -- we have to include the extra logic that marks up no-qc-pos OR ep unsucc, OR dna-bad
    # into this script, but we're not there yet.
    if ( $project->{project_status_id} == $project_status_dict->{'ES-NQP'}->{project_status_id} ) {
        return;
    }
    if ( $project->{project_status_id} == $project_status_dict->{'ES-EU'}->{project_status_id} ) {
        return;
    }
    
    #If we have positive colonies (but none of the above statuses), then mark the electroporation in progress
    if ( $project->{total_colonies} ){
        if ( $project->{total_colonies} > 0 ){
            if($project_status_dict_by_id->{$project->{project_status_id}}->{order_by} < $project_status_dict->{'ES-EP'}->{order_by}){
                $project->{project_status_id} = $project_status_dict->{'ES-EP'}->{project_status_id};
            }
        }
        return;
    }
    
    ## If the vector is good, say that.
    if ( $project->{targvec_pass_level} ) {
        if ( $project->{targvec_distribute} ) {
            if($project_status_dict_by_id->{$project->{project_status_id}}->{order_by} < $project_status_dict->{'TVC'}->{order_by}){
                $project->{project_status_id} = $project_status_dict->{'TVC'}->{project_status_id};
            }
            return;
        }
    }
            
    ## If the vector has a result but is NOT distributed, mark it unsuccessful
    if ( $project->{targvec_pass_level} ) {
        if($project_status_dict_by_id->{$project->{project_status_id}}->{order_by} < $project_status_dict->{'TV-IAU'}->{order_by}){
           $project->{project_status_id} = $project_status_dict->{'TV-IAU'}->{project_status_id};
        }
        return;
    }
            
    if($project_status_dict_by_id->{$project->{project_status_id}}->{order_by} < $project_status_dict->{'TVIP'}->{order_by}){
        $project->{project_status_id} = $project_status_dict->{'TVIP'}->{project_status_id};
    }
}

sub do_i_update_project {
    ##
    ## Compares a project object to a 'new_project' hashref to
    ## see if there are any differences (for updating)
    ##   - if they are the same, returns undef
    ##   - if they are diff, returns 1
    ##

    my ( $current_project, $new_project ) = @_;
    my $update_needed = undef;

    my $fields_to_check = [
        qw/
          project_status_id
          computational_gene_id
          is_publicly_reported
          is_komp_csd
          is_komp_regeneron
          is_eucomm
          is_norcomm
          is_mgp
          tmp_status
          status_id
          design_id
          design_instance_id
          bac
          intermediate_vector_id
          targeting_vector_id
          cassette
          backbone
          design_plate_name
          design_well_name
          intvec_plate_name
          intvec_well_name
          intvec_pass_level
          targvec_plate_name
          targvec_well_name
          targvec_pass_level
          total_colonies
          colonies_picked
          epd_distribute
          targeted_trap
          epd_recovered
          /
    ];

    foreach my $field ( @{$fields_to_check} ) {
        if ( defined $new_project->{$field} ) {
            if ( $new_project->{$field} =~ /^\w{1,}/ ) {
                if ( $new_project->{$field} ne $current_project->$field ) { $update_needed = 1; }
            } else {
                if ( $new_project->{$field} != $current_project->$field ) { $update_needed = 1; }
            }
        }
    }

    return $update_needed;
}

=head2

Retrieve all the alleles where the design-instance-id has changed between EP and EPD -- could
be due to mispicking, say.
Then get all the pipeline projects for that design_instance_id, either at the vector step or at the
ES-cell step.
Then see whether we can match up the vector-step to the allele-step by di + cassette + backbone.
Present the result as an array, keyed by di::cassette::backbone

=cut

sub get_alleles_with_altered_final_epd_di {
    
    my ($schema) = @_;
    
    my $conflict_sql = qq[
        select 
        distinct 
        ep_well.design_instance_id source_design_instance_id, 
        epd_well.design_instance_id target_design_instance_id
        from 
        design_instance,
        well epd_well, 
        well ep_well,
        well_data
        where
        design_instance.design_instance_id = epd_well.design_instance_id
        and epd_well.parent_well_id = ep_well.well_id
        and (epd_well.well_name like 'EPD%' or epd_well.well_name like 'HEPD%')
        and epd_well.design_instance_id != ep_well.design_instance_id
        and well_data.well_id = epd_well.well_id
        and data_type = 'distribute' and data_value = 'yes'
        order by source_design_instance_id, target_design_instance_id
    ];

    my $sth = $schema->storage->dbh->prepare($conflict_sql);
    $sth->execute();

    my $interesting_diids;
    while ( my @result = $sth->fetchrow_array ) {
        my ( $source_diid, $target_diid ) = @result;
        $interesting_diids->{$source_diid} = 1;
        $interesting_diids->{$target_diid} = 1;
    }
    
    my @keys = keys %$interesting_diids;
    #if ($debug) {print "INTERESTING DIs @keys\n"};

    my $vector_sql = qq[
        select distinct design_design_instance_id , cassette, backbone
        from ${well_summary}
        where 
        design_design_instance_id = ?
    ];

    my $clone_sql = qq[
        select
        distinct cassette, backbone, epd_design_instance_id ,
        sum( total_colonies ) total_colonies,
        sum( colonies_picked ) colonies_picked,
        sum( decode( epd_distribute, null, 0, 'yes', 1 )) epd_distribute,
        sum( decode( targeted_trap, null, 0, 'yes', 1 )) targeted_trap
        from ${well_summary}
        where 
        epd_design_instance_id  = ?
        and epd_distribute = 'yes'
        group by cassette, backbone, epd_design_instance_id
    ];

    my $vector_sth = $schema->storage->dbh->prepare($vector_sql);
    my $clone_sth  = $schema->storage->dbh->prepare($clone_sql);

    my $results_by_allele_key;

    foreach my $diid ( keys %$interesting_diids ) {

        my $vector_results;
        my $allele_results;

        $vector_sth->execute($diid);
        $clone_sth->execute($diid);
        my $tmp;

        #Stick together all the vectors and the alleles for an affected design-instance
        #if ($debug) {
        #    print "looking at di $diid\n";
        #}

        while ( my $result = $vector_sth->fetchrow_hashref ) {
            my $allele_key
              = $result->{DESIGN_DESIGN_INSTANCE_ID} . "::"
              . $result->{CASSETTE} . "::"
              . $result->{BACKBONE};
            my $tmp = {
                design_instance_id => $result->{DESIGN_DESIGN_INSTANCE_ID},
                cassette           => $result->{CASSETTE},
                backbone           => $result->{BACKBONE},
                total_colonies     => undef,
                colonies_picked    => undef,
                epd_distribute     => undef
            };
            $vector_results->{$allele_key} = $tmp;
            #if ($debug) {
            #    print "inserting vector for: $allele_key\n";
            #}
        }

        while ( my $result = $clone_sth->fetchrow_hashref ) {
            my $allele_key
              = $result->{EPD_DESIGN_INSTANCE_ID} . "::"
              . $result->{CASSETTE} . "::"
              . $result->{BACKBONE};
            my $tmp = {
                design_instance_id => $result->{EPD_DESIGN_INSTANCE_ID},
                cassette           => $result->{CASSETTE},
                backbone           => $result->{BACKBONE},
                total_colonies     => $result->{TOTAL_COLONIES},
                colonies_picked    => $result->{COLONIES_PICKED},
                epd_distribute     => $result->{EPD_DISTRIBUTE},
                targeted_trap      => $result->{TARGETED_TRAP}
            };
            $allele_results->{$allele_key} = $tmp;
            #if ($debug) {
            #    print "inserting distributed epd clones for: $allele_key\n";
            #}
        }

        #Now that you've keyed them, ask if there are any vectors with an allele-key that match
        #distributed ES cells with the same allele-key:
        #if ($debug) {
        #    my @vector_keys = keys %$vector_results;
        #    my @allele_keys = keys %$allele_results;
        #    print "vector keys: @vector_keys\n";
        #    print "allele keys: @allele_keys\n";
        #}

        foreach my $allele_key ( keys %$vector_results ) {
            if ( $allele_results->{$allele_key} ) {

                $results_by_allele_key->{$allele_key} = $allele_results->{$allele_key};

            } else {

                $results_by_allele_key->{$allele_key} = $vector_results->{$allele_key};

            }
        }
    }
    
    #if($debug){
    #    print "DI-changing epds: \n".Data::Dumper->Dump([$results_by_allele_key]);
    #}
    return $results_by_allele_key;
}

=head2
  This grabs all the EPD-results for the 'pgg' plates - which are currently distinguished by
=cut
sub get_alleles_for_pgg_plates {
    my ($schema) = @_;
    
    my $ep_sql = qq[
        select 
          ${well_summary}.ep_well_id,
          ${well_summary}.EP_PLATE_NAME,
          ${well_summary}.EP_WELL_NAME,
          sum( total_colonies ) total_colonies,
          sum( colonies_picked ) colonies_picked,
          sum( decode( epd_distribute, null, 0, 'yes', 1 )) epd_distribute,
          sum( decode( targeted_trap, null, 0, 'yes', 1 )) targeted_trap
          from 
          ${well_summary}
          where
          epd_design_instance_id in (
            (select distinct (epd_design_instance_id)
            from ${well_summary}
            where epd_distribute = 'yes'
            and pgdgr_design_instance_id is null
            )
          )
          group by 
          ${well_summary}.ep_well_id,
          ${well_summary}.EP_PLATE_NAME,
          ${well_summary}.EP_WELL_NAME
          order by ep_well_id
    ];
    
    my $tv_sql_2 = qq[
       select
       distinct tv_plate.name||'_'||tv_well.well_name tv_well_name, tv_well.well_id tv_well_id,
       ep_well.well_name ep_well_name, ep_well.well_id ep_well_id
       from  
       plate tv_plate, 
       well tv_well,  
       well ep_well, 
       well epd_well
       where 
       tv_well.plate_id = tv_plate.plate_id
       and tv_plate.type = 'PGD'
       and tv_well.well_id = ep_well.parent_well_id
       and ep_well.well_id = epd_well.parent_well_id 
       and (epd_well.well_name like 'EPD%' or epd_well.well_name like 'HEPD%')
       and epd_well.design_instance_id in (
            (select distinct (epd_design_instance_id)
            from ${well_summary}
            where (epd_distribute = 'yes' or targeted_trap = 'yes')
            and pgdgr_design_instance_id is null
            )
       )
    ];
    
    my $tv_sql = qq[
        select
        distinct tv_plate.name||'_'||tv_well.well_name tv_well_name, tv_well.well_id tv_well_id,
        ep_well.well_name ep_well_name, ep_well.well_id ep_well_id
        from  
        plate tv_plate, 
        well tv_well, 
        plate pgg_plate, 
        well pgg_well, 
        well ep_well, 
        well epd_well
        where 
        tv_well.plate_id = tv_plate.plate_id
        and tv_well.well_id = pgg_well.parent_well_id
        and pgg_well.well_id = ep_well.parent_well_id
        and pgg_plate.plate_id = pgg_well.plate_id
        and pgg_plate.type = 'PGG'
        and ep_well.well_id = epd_well.parent_well_id 
        and (epd_well.well_name like 'EPD%' or epd_well.well_name like 'HEPD%')
        and epd_well.design_instance_id in (
            (select distinct (epd_design_instance_id)
            from ${well_summary}
            where (epd_distribute = 'yes' or targeted_trap = 'yes')
            and pgdgr_design_instance_id is null
            )
        )
    ];
    
    my $results_by_ep_id;
    my $results_by_tv_id;
    
    my $tv_sth = $schema->storage->dbh->prepare($tv_sql);
    $tv_sth->execute();
    while( my $result = $tv_sth->fetchrow_hashref ){
        #if($debug){print "filling in results for ".$result->{EP_WELL_ID}."\n"};
        my $tmp = {
            tv_well_name => $result->{TV_WELL_NAME},
            tv_well_id   => $result->{TV_WELL_ID},
            ep_well_name => $result->{EP_WELL_NAME},
            ep_well_id   => $result->{EP_WELL_ID},
        };
        $results_by_ep_id->{$result->{EP_WELL_ID}} = $tmp;
    }
    
    my $tv_sth_2 = $schema->storage->dbh->prepare($tv_sql_2);
    $tv_sth_2->execute();
    while( my $result = $tv_sth_2->fetchrow_hashref ){
        #if($debug){print "filling in results (round 2) for ".$result->{EP_WELL_ID}."\n"};
        my $tmp = {
            tv_well_name => $result->{TV_WELL_NAME},
            tv_well_id   => $result->{TV_WELL_ID},
            ep_well_name => $result->{EP_WELL_NAME},
            ep_well_id   => $result->{EP_WELL_ID},
        };
        $results_by_ep_id->{$result->{EP_WELL_ID}} = $tmp;
    }
    
    my $ep_sth = $schema->storage->dbh->prepare($ep_sql);
    $ep_sth->execute();
    while( my $ep_result = $ep_sth->fetchrow_hashref ){
        #if($debug){print "adding epd result for ".$ep_result->{EP_WELL_ID}." with epd: ".$ep_result->{EPD_DISTRIBUTE}."\n"};
        my $tv_result = $results_by_ep_id->{$ep_result->{EP_WELL_ID}};
        # Pull the tv_result OUT of the hash by ep-id, and stick it INTO the hash by tv-id
        if($tv_result){
            $tv_result->{total_colonies} = $ep_result->{TOTAL_COLONIES}; 
            $tv_result->{colonies_picked} = $ep_result->{COLONIES_PICKED}; 
            $tv_result->{epd_distribute} = $ep_result->{EPD_DISTRIBUTE};
            $tv_result->{targeted_trap} = $ep_result->{TARGETED_TRAP};
            $results_by_tv_id->{$tv_result->{tv_well_id}} = $tv_result;
        }else{
           if($debug){print "got an ep result ".$ep_result->{EP_WELL_NAME}." without a corresponding tv result\n"}; 
        }
    }
    
    
    #if($debug){
    #      #print "looking for tv ".$row->{PGDGR_PLATE_NAME}."_".$row->{PGDGR_WELL_NAME}." with id: ".$row->{PGDGR_WELL_ID}."\n";
    #      my @tmp = sort {$a <=> $b} keys %{$results_by_tv_id};
    #      print "What are these pgg vector ids? @tmp\n";
    #}
    return $results_by_tv_id;
}

sub get_eucomm_ep_project_from_multiples {
    my $multiple_projects = shift;
    foreach my $project (@$multiple_projects){
        if( $project->is_eucomm && $project->esc_only ){
            return $project;
        }
    }
}

1;
