#!/usr/bin/perl -w
use strict;

use HTGT::DBFactory;

# Find all DEPD clones which SHOULD be distributable - via their repository loa + loxP calls
# Then make sure their distribute flag is set (if it's not already), but remove the tt flag
# (if that was already set)

my $cond_sql = qq[
(select distinct well_name
from well, repository_qc_result
where well.well_name like 'DEPD%'
and repository_qc_result.well_id = well.well_id
and repository_qc_result.loss_of_allele = 'pass'
and (repository_qc_result.threep_loxp_taqman = 'pass')
minus
select distinct epd_well_name  well_name
from well_summary_by_di
where epd_distribute = 'yes'
)
order by well_name
];

my $schema = HTGT::DBFactory->connect('eucomm_vector');
my $dbh = $schema->storage->dbh;
my $dryrun = 0;


my $del_sql = qq[
select distinct well_name
from design, design_instance, well, repository_qc_result
where well.well_name like 'DEPD%'
and repository_qc_result.well_id = well.well_id
and repository_qc_result.loss_of_allele = 'pass'
and design_instance.design_instance_id = well.design_instance_id
and design.design_id = design_instance.design_id
and design.design_type like 'Del%'
minus
select distinct epd_well_name  well_name
from well_summary_by_di
where epd_distribute = 'yes'
];

my $tt_sql = qq[
(select distinct well_name
from design, design_instance, well, repository_qc_result
where well.well_name like 'DEPD%'
and repository_qc_result.well_id = well.well_id
and repository_qc_result.loss_of_allele = 'pass'
and (repository_qc_result.threep_loxp_taqman = 'fail')
and design_instance.design_instance_id = well.design_instance_id
and design.design_id = design_instance.design_id
and (design.design_type is null or design.design_type like 'KO%')
minus
select distinct epd_well_name  well_name
from well_summary_by_di
where (epd_distribute = 'yes' or targeted_trap = 'yes')
)    
];

print "starting epd finding\n";
my $cond_sth = $dbh->prepare($cond_sql);
$cond_sth->execute();
my $del_sth = $dbh->prepare($del_sql);
$del_sth->execute();
my $tt_sth = $dbh->prepare($tt_sql);
$tt_sth->execute();
print "finished epd finding\n";

$schema->txn_do(sub {
    
    print "setting distribute for conditionals\n";
    while(my ($well_name) = $cond_sth->fetchrow_array()){
        make_dist_flag($well_name);
    }
    
    print "setting distribute for deletions\n";
    while(my $well_name = $del_sth->fetchrow_array()){
        make_dist_flag($well_name);
    }
    
    print "setting tt for conditionals\n";
    while(my $well_name = $tt_sth->fetchrow_array()){
        make_tt_flag($well_name);
    }
    if($dryrun){
        die "ROLLBACK  - dry run \n";
    }
});


sub make_dist_flag {
    my $well_name = shift;
    die "well name $well_name doesn't look like DEPD...\n" unless ($well_name =~ /^DEPD/);
    my @wells = $schema->resultset('HTGTDB::Well')->search({well_name => $well_name});
    die "no htgt wells with name $well_name" unless $wells[0];
    my $well = $wells[0];
    
    if($well->well_data->search({data_type=>'distribute'})->count() == 1){
        print "well $well_name already is distributable\n";
        return;
    }else{
        my @well_data = $well->well_data->search({data_type=>'targeted_trap'});
        if($well_data[0]){
            print "well $well_name already is tt - removing\n";
        }
        $schema->resultset('HTGTDB::WellData')->create(
            { well_id => $well->well_id, data_type=>'distribute', data_value=>'yes', edit_user=>'vvi', edit_date=>'10-JUL-2011'}
        );
        print "created distribute flag on $well_name\n";
    }
}

sub make_tt_flag {
    my $well_name = shift;
    die "well name $well_name doesn't look like DEPD...\n" unless ($well_name =~ /^DEPD/);
    my @wells = $schema->resultset('HTGTDB::Well')->search({well_name => $well_name});
    die "no htgt wells with name $well_name" unless $wells[0];
    my $well = $wells[0];
    
    if($well->well_data->search({data_type=>'targeted_trap'})->count() == 1){
        print "well $well_name already is targeted_trap\n";
        next;
    }else{
        my @well_data = $well->well_data->search({data_type=>'distribute'});
        if($well_data[0]){
            print "well $well_name already is distribute - removing\n";
        }
        $schema->resultset('HTGTDB::WellData')->create(
            { well_id => $well->well_id, data_type=>'targeted_trap', data_value=>'yes', edit_user=>'vvi', edit_date=>'10-JUL-2011'}
        );
        print "created distribute flag on $well_name\n";
    }    
}
