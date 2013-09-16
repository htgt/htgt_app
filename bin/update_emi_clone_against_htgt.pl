use strict;
use warnings FATAL => 'all';
use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory;
use DateTime;

GetOptions(
    'help' => \my $help,
    'commit' => \my $commit,
) or pod2usage(2);

pod2usage(1) if $help;

my $htgt_schema = HTGT::DBFactory->connect('eucomm_vector');
my $kermit_schema = HTGT::DBFactory->connect('kermits');

my $sql = <<'EOT';
select well_summary_by_di.epd_well_name, well_summary_by_di.ALLELE_NAME, well_summary_by_di.ES_CELL_LINE, mgi_gene.marker_symbol,
project.is_eucomm, project.is_komp_csd
from well_summary_by_di 
join project on well_summary_by_di.project_id = project.project_id
join mgi_gene on mgi_gene.mgi_gene_id = project.mgi_gene_id
where (well_summary_by_di.epd_distribute='yes' or well_summary_by_di.targeted_trap = 'yes')
and (is_eucomm = 1 or is_komp_csd = 1)
EOT

my $sth = $htgt_schema->storage->dbh()->prepare($sql);
$sth->execute();

my $number_of_updated = 0;
my $number_of_created = 0;

$kermit_schema->txn_do(
    sub {
	while (my $htgt_clone = $sth->fetchrow_hashref){
	    my $emi_clone = $kermit_schema->resultset('KermitsDB::EmiClone')->search({ clone_name => $htgt_clone->{EPD_WELL_NAME}})->first;   
	    if (!$emi_clone ){
		#create a new entry
		print "clone not found in kermits, create an entry for $htgt_clone->{EPD_WELL_NAME}\n";
		my $pipeline_id;
		if ( $htgt_clone->{IS_EUCOMM} and $htgt_clone->{IS_EUCOMM} == 1 ){
		    $pipeline_id = 1;
		}elsif($htgt_clone->{IS_KOMP_CSD} and $htgt_clone->{IS_KOMP_CSD} == 1 ){
		    $pipeline_id = 2;
		}
	
		$kermit_schema->resultset('KermitsDB::EmiClone')->create(
		    {   clone_name => $htgt_clone->{EPD_WELL_NAME},
			created_date => \'current_timestamp',
			creator_id => 26,
			pipeline_id => $pipeline_id,
			gene_symbol => $htgt_clone->{MARKER_SYMBOL},
			allele_name => $htgt_clone->{ALLELE_NAME},
			es_cell_line => $htgt_clone->{ES_CELL_LINE}
		    });
		$number_of_created++;
	    }
	    elsif ($emi_clone and ($emi_clone->gene_symbol ne $htgt_clone->{MARKER_SYMBOL})){
		#update the entry
		my $old_symbol = $emi_clone->gene_symbol;
		print "gene symbol update from  $old_symbol to $htgt_clone->{MARKER_SYMBOL}\n";
		$emi_clone->update({
		    gene_symbol => $htgt_clone->{MARKER_SYMBOL},
		    allele_name => $htgt_clone->{ALLELE_NAME},
		    es_cell_line => $htgt_clone->{ES_CELL_LINE},
		    edit_date => \'current_timestamp',
		    edited_by => 'vvi'
		});
		$number_of_updated++;
	    }   
	}
	
	unless ($commit){
	    print "rollback changes\n";
	    $kermit_schema->txn_rollback;
	}
    }
);

print "Total number of created clones: $number_of_created \n";
print "Total number of updated clones: $number_of_updated \n";