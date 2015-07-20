use utf8;
package Tarmits::Schema::Result::PhenotypingProduction;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::PhenotypingProduction

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<phenotyping_productions>

=cut

__PACKAGE__->table("phenotyping_productions");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenotyping_productions_id_seq'

=head2 mi_plan_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 mouse_allele_mod_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 colony_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 phenotyping_experiments_started

  data_type: 'date'
  is_nullable: 1

=head2 phenotyping_started

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 phenotyping_complete

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

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

=head2 ready_for_website

  data_type: 'date'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenotyping_productions_id_seq",
  },
  "mi_plan_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "mouse_allele_mod_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "colony_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "phenotyping_experiments_started",
  { data_type => "date", is_nullable => 1 },
  "phenotyping_started",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "phenotyping_complete",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
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
  "ready_for_website",
  { data_type => "date", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

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

=head2 mouse_allele_mod

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MouseAlleleMod>

=cut

__PACKAGE__->belongs_to(
  "mouse_allele_mod",
  "Tarmits::Schema::Result::MouseAlleleMod",
  { id => "mouse_allele_mod_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
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

=head2 phenotyping_production_status_stamps

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypingProductionStatusStamp>

=cut

__PACKAGE__->has_many(
  "phenotyping_production_status_stamps",
  "Tarmits::Schema::Result::PhenotypingProductionStatusStamp",
  { "foreign.phenotyping_production_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 status

Type: belongs_to

Related object: L<Tarmits::Schema::Result::PhenotypingProductionStatus>

=cut

__PACKAGE__->belongs_to(
  "status",
  "Tarmits::Schema::Result::PhenotypingProductionStatus",
  { id => "status_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UNeRaSWANqn7qhzsUEXZNQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
