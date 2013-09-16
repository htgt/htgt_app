package HTGT::Utils::ProjectStatusUpdater;

use strict;
use warnings FATAL => 'all';
use HTGT::DBFactory;
use Data::Dumper;
use List::MoreUtils qw/any/;

sub update_project {
    my $test_subset = shift;
    my $schema = HTGT::DBFactory->connect('eucomm_vector');
    
    my $projects_by_code;
    foreach my $status ( $schema->resultset('HTGTDB::ProjectStatus')->all() ){
	$projects_by_code->{$status->code} = $status;
    }

    # read the new_well_summary data and get pipeline projects by di and project id
    my $projects = get_pipeline_projects($schema, $test_subset);
    
    foreach my $di ( keys %$projects ){
	my $projects_for_di = $projects->{$di};
	
	foreach my $project_id (keys %$projects_for_di){
	    print "project id: ".$project_id."\n";
	    my @es_cells;
	    foreach my $project (@{$projects_for_di->{$project_id}}){
		# collect all es cells
		if ($project->{EPD_DISTRIBUTE}){
		    push @es_cells, $project->{EPD_WELL_NAME};
		}
    	    }
	    
	    # if there are epd distribute flag, go to check kermit for more advanced status
	    if ( scalar(@es_cells) >0 ){
		# check in kermit for every es cells to find the latest status
		my $status = check_kermit(\@es_cells, $projects_by_code);
		print $status->code."\n";
		# update the project with the status returned
		my $project = $schema->resultset('HTGTDB::Project')->find($project_id);
		#
		my $current_status_order_by = $project->status->order_by;
		#
		if( $current_status_order_by < $status->order_by ){
		    print "Changing $current_status_order_by to ".$status->order_by." for project ".$project->project_id."\n";
		#    if ( $updatedb ) {
			print "Doing update: \n";
			$project->update({project_status_id=>$status->project_status_id, edit_user=>'team87'});
		  #  }
		}
	    }else{
		print "less than EC-TC\n";
		# decide which status, assign each row with its own status and choose the latest one?
	    }
	}
    }
}

sub get_pipeline_projects {
    my ( $schema, $test_subset ) = @_;
    
    my $sql = qq [
    select 
    project_id,design_instance_id, cassette, backbone,
    design_plate_name,design_well_name,
    pcs_plate_name,pcs_well_name,pc_pass_level,pcs_distribute,
    pgdgr_plate_name, pgdgr_well_name, pgdgr_clone_name, pg_pass_level,pgdgr_distribute,
    grq_plate_name, grq_well_name, grq_pass_level,grq_distribute,
    pgg_plate_name,pgg_well_name,pgg_pass_level,pgg_distribute, dna_status,
    ep_plate_name, ep_well_name,
    colonies_picked, total_colonies,
    epd_plate_name,epd_well_name,epd_pass_level,epd_distribute,
    fp_plate_name, fp_well_name,
    targeted_trap
    from new_well_summary
    $test_subset
    order by design_instance_id, design_plate_name, pcs_plate_name, pgdgr_plate_name, ep_plate_name, epd_plate_name
];
    
    my $sth = $schema->storage->dbh()->prepare($sql);
    $sth->execute();
    #print $sql."\n";
    my %projects;
    while ( my $result = $sth->fetchrow_hashref()){
	my $di = $result->{DESIGN_INSTANCE_ID};
	my $project_id = $result->{PROJECT_ID};
	push @{$projects{$di}{$project_id}}, $result;
    }
    
    return \%projects;
}

# given a list of es clones and find the latest status for these clones in kermit
sub check_kermit {
    my ($es_cells, $projects_by_code) = @_;
    # set initial status
    my $status = $projects_by_code->{'ES-TC'};
    
    # find the mi attempt for these clones
    my $schema = HTGT::DBFactory->connect('kermits');
    my $sql = qq [
	select centre_id, clone_name, is_active, number_het_offspring,
	chimeras_with_glt_from_genotyp,chimeras_with_glt_from_cct,number_with_cct,num_blasts
	from 
	emi_clone, emi_attempt, emi_event
	where 
	emi_attempt.EVENT_ID = emi_event.ID
	and
	emi_event.CLONE_ID = emi_clone.ID
	and
	clone_name in (
    ];
    
    my $esc_list = '';
    foreach my $esc (@$es_cells){
	$esc_list = $esc_list."'". $esc."',";
    }
    
    $sql = $sql.$esc_list;
    $sql = substr($sql, 0, -1).")";

    my $sth = $schema->storage->dbh()->prepare($sql);
    $sth->execute();
    # loop through these mi attempts, if found more advanced status, replace the default one
    while ( my $mi = $sth->fetchrow_hashref() ){
	# IF we have a SANGER clone to be GC it requires >= 5 het offspring
	if ( $mi->{CENTRE_ID} == 1 and ( $mi->{NUMBER_HET_OFFSPRING} and $mi->{NUMBER_HET_OFFSPRING} >= 5 )){
	    if ( $status->order_by < $projects_by_code->{'M-GC'}->order_by ){
		$status = $projects_by_code->{'M-GC'};
	    }
	}
	
	# If it ISN'T a SANGER clone, to be GC it can have either 1 or more het off spring or GC confirmed chimeras
	elsif ( $mi->{CENTRE_ID} != 1 and ( ($mi->{NUMBER_HET_OFFSPRING} and $mi->{NUMBER_HET_OFFSPRING} > 0) or ( $mi->{CHIMERAS_WITH_GLT_FROM_GENOTYP} and $mi->{CHIMERAS_WITH_GLT_FROM_GENOTYP} > 0) )){
	    if ( $status->order_by < $projects_by_code->{'M-GC'}->order_by ){
		$status = $projects_by_code->{'M-GC'};
	    }
	}
	
	# Otherwise if there is coat color transmission then it's GLT - projects don't matter here.
	elsif ( ($mi->{NUMBER_WITH_CCT} and $mi->{NUMBER_WITH_CCT} > 0)  or  ( $mi->{CHIMERAS_WITH_GLT_FROM_CCT} and $mi->{CHIMERAS_WITH_GLT_FROM_CCT} > 0 ) ) {
	    if ( ( $status->order_by < $projects_by_code->{'M-GLT'}->order_by )  ) {
                $status = $projects_by_code->{'M-GLT'}
            }
	}
	
	# Any number of blasts (abr) and woo, we have a micro-injection in progress
	elsif ( $mi->{NUM_BLASTS} and $mi->{NUM_BLASTS} > 0 ) {
	    if ( $status->order_by < $projects_by_code->{'M-MIP'}->order_by ) {
		$status = $projects_by_code->{'M-MIP'} 
	    }
	}
    }

    return $status;
}

1;