use utf8;
package Tarmits::Schema::Result::Centre;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::Centre

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<centres>

=cut

__PACKAGE__->table("centres");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'centres_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 contact_name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 contact_email

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 code

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
    sequence          => "centres_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "contact_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "contact_email",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "code",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<index_centres_on_name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("index_centres_on_name", ["name"]);

=head1 RELATIONS

=head2 mi_attempt_distribution_centres

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttemptDistributionCentre>

=cut

__PACKAGE__->has_many(
  "mi_attempt_distribution_centres",
  "Tarmits::Schema::Result::MiAttemptDistributionCentre",
  { "foreign.centre_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_plans

Type: has_many

Related object: L<Tarmits::Schema::Result::MiPlan>

=cut

__PACKAGE__->has_many(
  "mi_plans",
  "Tarmits::Schema::Result::MiPlan",
  { "foreign.production_centre_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_attempt_distribution_centres

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypeAttemptDistributionCentre>

=cut

__PACKAGE__->has_many(
  "phenotype_attempt_distribution_centres",
  "Tarmits::Schema::Result::PhenotypeAttemptDistributionCentre",
  { "foreign.centre_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 targ_rep_es_cells

Type: has_many

Related object: L<Tarmits::Schema::Result::TargRepEsCell>

=cut

__PACKAGE__->has_many(
  "targ_rep_es_cells",
  "Tarmits::Schema::Result::TargRepEsCell",
  { "foreign.user_qc_mouse_clinic_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SclTa4AfyZnhorCVcfXHbg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
