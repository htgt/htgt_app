use utf8;
package Tarmits::Schema::Result::MiAttemptDistributionCentre;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::MiAttemptDistributionCentre

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<mi_attempt_distribution_centres>

=cut

__PACKAGE__->table("mi_attempt_distribution_centres");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'mi_attempt_distribution_centres_id_seq'

=head2 start_date

  data_type: 'date'
  is_nullable: 1

=head2 end_date

  data_type: 'date'
  is_nullable: 1

=head2 mi_attempt_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 deposited_material_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 centre_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_distributed_by_emma

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 distribution_network

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 reconciled

  data_type: 'varchar'
  default_value: 'not checked'
  is_nullable: 0
  size: 255

=head2 reconciled_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 available

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mi_attempt_distribution_centres_id_seq",
  },
  "start_date",
  { data_type => "date", is_nullable => 1 },
  "end_date",
  { data_type => "date", is_nullable => 1 },
  "mi_attempt_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "deposited_material_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "centre_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_distributed_by_emma",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "distribution_network",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "reconciled",
  {
    data_type => "varchar",
    default_value => "not checked",
    is_nullable => 0,
    size => 255,
  },
  "reconciled_at",
  { data_type => "timestamp", is_nullable => 1 },
  "available",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 centre

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Centre>

=cut

__PACKAGE__->belongs_to(
  "centre",
  "Tarmits::Schema::Result::Centre",
  { id => "centre_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 deposited_material

Type: belongs_to

Related object: L<Tarmits::Schema::Result::DepositedMaterial>

=cut

__PACKAGE__->belongs_to(
  "deposited_material",
  "Tarmits::Schema::Result::DepositedMaterial",
  { id => "deposited_material_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:txYVcLnbSO5IchkaWjuE2w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
