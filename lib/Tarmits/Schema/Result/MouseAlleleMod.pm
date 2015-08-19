use utf8;
package Tarmits::Schema::Result::MouseAlleleMod;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::MouseAlleleMod

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<mouse_allele_mods>

=cut

__PACKAGE__->table("mouse_allele_mods");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'mouse_allele_mods_id_seq'

=head2 mi_plan_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 mi_attempt_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 rederivation_started

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 rederivation_complete

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 number_of_cre_matings_started

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 number_of_cre_matings_successful

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 no_modification_required

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 cre_excision

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 tat_cre

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 mouse_allele_type

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 allele_category

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 deleter_strain_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 colony_background_strain_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 colony_name

  data_type: 'varchar'
  is_nullable: 0
  size: 125

=head2 is_active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 report_to_public

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 phenotype_attempt_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 0

=head2 qc_southern_blot_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_five_prime_lr_pcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_five_prime_cassette_integrity_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_tv_backbone_assay_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_neo_count_qpcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_neo_sr_pcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_loa_qpcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_homozygous_loa_sr_pcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_lacz_sr_pcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_mutant_specific_sr_pcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_loxp_confirmation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_three_prime_lr_pcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_lacz_count_qpcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_critical_region_qpcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_loxp_srpcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_loxp_srpcr_and_sequencing_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 allele_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 real_allele_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 allele_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 allele_mgi_accession_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mouse_allele_mods_id_seq",
  },
  "mi_plan_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "mi_attempt_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "rederivation_started",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "rederivation_complete",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "number_of_cre_matings_started",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "number_of_cre_matings_successful",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "no_modification_required",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "cre_excision",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "tat_cre",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "mouse_allele_type",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "allele_category",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "deleter_strain_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "colony_background_strain_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "colony_name",
  { data_type => "varchar", is_nullable => 0, size => 125 },
  "is_active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "report_to_public",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "phenotype_attempt_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "created_at",
  { data_type => "timestamp", is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 0 },
  "qc_southern_blot_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_five_prime_lr_pcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_five_prime_cassette_integrity_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_tv_backbone_assay_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_neo_count_qpcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_neo_sr_pcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_loa_qpcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_homozygous_loa_sr_pcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_lacz_sr_pcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_mutant_specific_sr_pcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_loxp_confirmation_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_three_prime_lr_pcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_lacz_count_qpcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_critical_region_qpcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_loxp_srpcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_loxp_srpcr_and_sequencing_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "allele_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "real_allele_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "allele_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "allele_mgi_accession_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 allele

Type: belongs_to

Related object: L<Tarmits::Schema::Result::TargRepAllele>

=cut

__PACKAGE__->belongs_to(
  "allele",
  "Tarmits::Schema::Result::TargRepAllele",
  { id => "allele_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 colony_background_strain

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Strain>

=cut

__PACKAGE__->belongs_to(
  "colony_background_strain",
  "Tarmits::Schema::Result::Strain",
  { id => "colony_background_strain_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 deleter_strain

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Strain>

=cut

__PACKAGE__->belongs_to(
  "deleter_strain",
  "Tarmits::Schema::Result::Strain",
  { id => "deleter_strain_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 mi_attempt

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->belongs_to(
  "mi_attempt",
  "Tarmits::Schema::Result::MiAttempt",
  { id => "mi_attempt_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 mi_plan

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MiPlan>

=cut

__PACKAGE__->belongs_to(
  "mi_plan",
  "Tarmits::Schema::Result::MiPlan",
  { id => "mi_plan_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 mouse_allele_mod_status_stamps

Type: has_many

Related object: L<Tarmits::Schema::Result::MouseAlleleModStatusStamp>

=cut

__PACKAGE__->has_many(
  "mouse_allele_mod_status_stamps",
  "Tarmits::Schema::Result::MouseAlleleModStatusStamp",
  { "foreign.mouse_allele_mod_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_attempt

Type: belongs_to

Related object: L<Tarmits::Schema::Result::PhenotypeAttempt>

=cut

__PACKAGE__->belongs_to(
  "phenotype_attempt",
  "Tarmits::Schema::Result::PhenotypeAttempt",
  { id => "phenotype_attempt_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 phenotype_attempt_distribution_centres

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypeAttemptDistributionCentre>

=cut

__PACKAGE__->has_many(
  "phenotype_attempt_distribution_centres",
  "Tarmits::Schema::Result::PhenotypeAttemptDistributionCentre",
  { "foreign.mouse_allele_mod_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotyping_productions

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypingProduction>

=cut

__PACKAGE__->has_many(
  "phenotyping_productions",
  "Tarmits::Schema::Result::PhenotypingProduction",
  { "foreign.mouse_allele_mod_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_critical_region_qpcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_critical_region_qpcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_critical_region_qpcr_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_five_prime_cassette_integrity

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_five_prime_cassette_integrity",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_five_prime_cassette_integrity_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_five_prime_lr_pcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_five_prime_lr_pcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_five_prime_lr_pcr_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_homozygous_loa_sr_pcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_homozygous_loa_sr_pcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_homozygous_loa_sr_pcr_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_lacz_count_qpcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_lacz_count_qpcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_lacz_count_qpcr_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_lacz_sr_pcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_lacz_sr_pcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_lacz_sr_pcr_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_loa_qpcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_loa_qpcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_loa_qpcr_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_loxp_confirmation

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_loxp_confirmation",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_loxp_confirmation_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_loxp_srpcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_loxp_srpcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_loxp_srpcr_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_loxp_srpcr_and_sequencing

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_loxp_srpcr_and_sequencing",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_loxp_srpcr_and_sequencing_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_mutant_specific_sr_pcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_mutant_specific_sr_pcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_mutant_specific_sr_pcr_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_neo_count_qpcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_neo_count_qpcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_neo_count_qpcr_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_neo_sr_pcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_neo_sr_pcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_neo_sr_pcr_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_southern_blot

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_southern_blot",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_southern_blot_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_three_prime_lr_pcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_three_prime_lr_pcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_three_prime_lr_pcr_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qc_tv_backbone_assay

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_tv_backbone_assay",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_tv_backbone_assay_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 real_allele

Type: belongs_to

Related object: L<Tarmits::Schema::Result::TargRepRealAllele>

=cut

__PACKAGE__->belongs_to(
  "real_allele",
  "Tarmits::Schema::Result::TargRepRealAllele",
  { id => "real_allele_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 status

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MouseAlleleModStatus>

=cut

__PACKAGE__->belongs_to(
  "status",
  "Tarmits::Schema::Result::MouseAlleleModStatus",
  { id => "status_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:d+vbzu7cpQt8SimFKbRJDA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
