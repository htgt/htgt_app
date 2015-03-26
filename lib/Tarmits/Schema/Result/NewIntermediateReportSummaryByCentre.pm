use utf8;
package Tarmits::Schema::Result::NewIntermediateReportSummaryByCentre;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::NewIntermediateReportSummaryByCentre

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<new_intermediate_report_summary_by_centre>

=cut

__PACKAGE__->table("new_intermediate_report_summary_by_centre");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'new_intermediate_report_summary_by_centre_id_seq'

=head2 mi_plan_id

  data_type: 'integer'
  is_nullable: 1

=head2 mi_attempt_id

  data_type: 'integer'
  is_nullable: 1

=head2 mouse_allele_mod_id

  data_type: 'integer'
  is_nullable: 1

=head2 phenotyping_production_id

  data_type: 'integer'
  is_nullable: 1

=head2 overall_status

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 mi_plan_status

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 mi_attempt_status

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 phenotype_attempt_status

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 production_centre

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 gene

  data_type: 'varchar'
  is_nullable: 0
  size: 75

=head2 mgi_accession_id

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 gene_interest_date

  data_type: 'date'
  is_nullable: 1

=head2 mi_attempt_colony_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 mouse_allele_mod_colony_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 production_colony_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 assigned_date

  data_type: 'date'
  is_nullable: 1

=head2 assigned_es_cell_qc_in_progress_date

  data_type: 'date'
  is_nullable: 1

=head2 assigned_es_cell_qc_complete_date

  data_type: 'date'
  is_nullable: 1

=head2 aborted_es_cell_qc_failed_date

  data_type: 'date'
  is_nullable: 1

=head2 micro_injection_in_progress_date

  data_type: 'date'
  is_nullable: 1

=head2 chimeras_obtained_date

  data_type: 'date'
  is_nullable: 1

=head2 genotype_confirmed_date

  data_type: 'date'
  is_nullable: 1

=head2 micro_injection_aborted_date

  data_type: 'date'
  is_nullable: 1

=head2 phenotype_attempt_registered_date

  data_type: 'date'
  is_nullable: 1

=head2 rederivation_started_date

  data_type: 'date'
  is_nullable: 1

=head2 rederivation_complete_date

  data_type: 'date'
  is_nullable: 1

=head2 cre_excision_started_date

  data_type: 'date'
  is_nullable: 1

=head2 cre_excision_complete_date

  data_type: 'date'
  is_nullable: 1

=head2 phenotyping_started_date

  data_type: 'date'
  is_nullable: 1

=head2 phenotyping_experiments_started_date

  data_type: 'date'
  is_nullable: 1

=head2 phenotyping_complete_date

  data_type: 'date'
  is_nullable: 1

=head2 phenotype_attempt_aborted_date

  data_type: 'date'
  is_nullable: 1

=head2 phenotyping_mi_attempt_consortium

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 phenotyping_mi_attempt_production_centre

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 tm1b_phenotype_attempt_status

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 tm1b_phenotype_attempt_registered_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1b_rederivation_started_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1b_rederivation_complete_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1b_cre_excision_started_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1b_cre_excision_complete_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1b_phenotyping_started_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1b_phenotyping_experiments_started_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1b_phenotyping_complete_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1b_phenotype_attempt_aborted_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1b_colony_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 tm1b_phenotyping_production_colony_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 tm1b_phenotyping_mi_attempt_consortium

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 tm1b_phenotyping_mi_attempt_production_centre

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 tm1a_phenotype_attempt_status

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 tm1a_phenotype_attempt_registered_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1a_rederivation_started_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1a_rederivation_complete_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1a_cre_excision_started_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1a_cre_excision_complete_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1a_phenotyping_started_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1a_phenotyping_experiments_started_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1a_phenotyping_complete_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1a_phenotype_attempt_aborted_date

  data_type: 'date'
  is_nullable: 1

=head2 tm1a_colony_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 tm1a_phenotyping_production_colony_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 tm1a_phenotyping_mi_attempt_consortium

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 tm1a_phenotyping_mi_attempt_production_centre

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 distinct_genotype_confirmed_es_cells

  data_type: 'integer'
  is_nullable: 1

=head2 distinct_old_genotype_confirmed_es_cells

  data_type: 'integer'
  is_nullable: 1

=head2 distinct_non_genotype_confirmed_es_cells

  data_type: 'integer'
  is_nullable: 1

=head2 distinct_old_non_genotype_confirmed_es_cells

  data_type: 'integer'
  is_nullable: 1

=head2 total_pipeline_efficiency_gene_count

  data_type: 'integer'
  is_nullable: 1

=head2 total_old_pipeline_efficiency_gene_count

  data_type: 'integer'
  is_nullable: 1

=head2 gc_pipeline_efficiency_gene_count

  data_type: 'integer'
  is_nullable: 1

=head2 gc_old_pipeline_efficiency_gene_count

  data_type: 'integer'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "new_intermediate_report_summary_by_centre_id_seq",
  },
  "mi_plan_id",
  { data_type => "integer", is_nullable => 1 },
  "mi_attempt_id",
  { data_type => "integer", is_nullable => 1 },
  "mouse_allele_mod_id",
  { data_type => "integer", is_nullable => 1 },
  "phenotyping_production_id",
  { data_type => "integer", is_nullable => 1 },
  "overall_status",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "mi_plan_status",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "mi_attempt_status",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "phenotype_attempt_status",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "production_centre",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "gene",
  { data_type => "varchar", is_nullable => 0, size => 75 },
  "mgi_accession_id",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "gene_interest_date",
  { data_type => "date", is_nullable => 1 },
  "mi_attempt_colony_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "mouse_allele_mod_colony_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "production_colony_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "assigned_date",
  { data_type => "date", is_nullable => 1 },
  "assigned_es_cell_qc_in_progress_date",
  { data_type => "date", is_nullable => 1 },
  "assigned_es_cell_qc_complete_date",
  { data_type => "date", is_nullable => 1 },
  "aborted_es_cell_qc_failed_date",
  { data_type => "date", is_nullable => 1 },
  "micro_injection_in_progress_date",
  { data_type => "date", is_nullable => 1 },
  "chimeras_obtained_date",
  { data_type => "date", is_nullable => 1 },
  "genotype_confirmed_date",
  { data_type => "date", is_nullable => 1 },
  "micro_injection_aborted_date",
  { data_type => "date", is_nullable => 1 },
  "phenotype_attempt_registered_date",
  { data_type => "date", is_nullable => 1 },
  "rederivation_started_date",
  { data_type => "date", is_nullable => 1 },
  "rederivation_complete_date",
  { data_type => "date", is_nullable => 1 },
  "cre_excision_started_date",
  { data_type => "date", is_nullable => 1 },
  "cre_excision_complete_date",
  { data_type => "date", is_nullable => 1 },
  "phenotyping_started_date",
  { data_type => "date", is_nullable => 1 },
  "phenotyping_experiments_started_date",
  { data_type => "date", is_nullable => 1 },
  "phenotyping_complete_date",
  { data_type => "date", is_nullable => 1 },
  "phenotype_attempt_aborted_date",
  { data_type => "date", is_nullable => 1 },
  "phenotyping_mi_attempt_consortium",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "phenotyping_mi_attempt_production_centre",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "tm1b_phenotype_attempt_status",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "tm1b_phenotype_attempt_registered_date",
  { data_type => "date", is_nullable => 1 },
  "tm1b_rederivation_started_date",
  { data_type => "date", is_nullable => 1 },
  "tm1b_rederivation_complete_date",
  { data_type => "date", is_nullable => 1 },
  "tm1b_cre_excision_started_date",
  { data_type => "date", is_nullable => 1 },
  "tm1b_cre_excision_complete_date",
  { data_type => "date", is_nullable => 1 },
  "tm1b_phenotyping_started_date",
  { data_type => "date", is_nullable => 1 },
  "tm1b_phenotyping_experiments_started_date",
  { data_type => "date", is_nullable => 1 },
  "tm1b_phenotyping_complete_date",
  { data_type => "date", is_nullable => 1 },
  "tm1b_phenotype_attempt_aborted_date",
  { data_type => "date", is_nullable => 1 },
  "tm1b_colony_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "tm1b_phenotyping_production_colony_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "tm1b_phenotyping_mi_attempt_consortium",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "tm1b_phenotyping_mi_attempt_production_centre",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "tm1a_phenotype_attempt_status",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "tm1a_phenotype_attempt_registered_date",
  { data_type => "date", is_nullable => 1 },
  "tm1a_rederivation_started_date",
  { data_type => "date", is_nullable => 1 },
  "tm1a_rederivation_complete_date",
  { data_type => "date", is_nullable => 1 },
  "tm1a_cre_excision_started_date",
  { data_type => "date", is_nullable => 1 },
  "tm1a_cre_excision_complete_date",
  { data_type => "date", is_nullable => 1 },
  "tm1a_phenotyping_started_date",
  { data_type => "date", is_nullable => 1 },
  "tm1a_phenotyping_experiments_started_date",
  { data_type => "date", is_nullable => 1 },
  "tm1a_phenotyping_complete_date",
  { data_type => "date", is_nullable => 1 },
  "tm1a_phenotype_attempt_aborted_date",
  { data_type => "date", is_nullable => 1 },
  "tm1a_colony_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "tm1a_phenotyping_production_colony_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "tm1a_phenotyping_mi_attempt_consortium",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "tm1a_phenotyping_mi_attempt_production_centre",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "distinct_genotype_confirmed_es_cells",
  { data_type => "integer", is_nullable => 1 },
  "distinct_old_genotype_confirmed_es_cells",
  { data_type => "integer", is_nullable => 1 },
  "distinct_non_genotype_confirmed_es_cells",
  { data_type => "integer", is_nullable => 1 },
  "distinct_old_non_genotype_confirmed_es_cells",
  { data_type => "integer", is_nullable => 1 },
  "total_pipeline_efficiency_gene_count",
  { data_type => "integer", is_nullable => 1 },
  "total_old_pipeline_efficiency_gene_count",
  { data_type => "integer", is_nullable => 1 },
  "gc_pipeline_efficiency_gene_count",
  { data_type => "integer", is_nullable => 1 },
  "gc_old_pipeline_efficiency_gene_count",
  { data_type => "integer", is_nullable => 1 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:52avx40YpIwWbAyqCUrfcg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
