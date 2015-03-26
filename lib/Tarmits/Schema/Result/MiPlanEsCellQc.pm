use utf8;
package Tarmits::Schema::Result::MiPlanEsCellQc;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::MiPlanEsCellQc

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<mi_plan_es_cell_qcs>

=cut

__PACKAGE__->table("mi_plan_es_cell_qcs");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'mi_plan_es_cell_qcs_id_seq'

=head2 number_starting_qc

  data_type: 'integer'
  is_nullable: 1

=head2 number_passing_qc

  data_type: 'integer'
  is_nullable: 1

=head2 mi_plan_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mi_plan_es_cell_qcs_id_seq",
  },
  "number_starting_qc",
  { data_type => "integer", is_nullable => 1 },
  "number_passing_qc",
  { data_type => "integer", is_nullable => 1 },
  "mi_plan_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "created_at",
  { data_type => "timestamp", is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 0 },
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
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OiKAzOlu6OdYRCL1Rr8KsQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
