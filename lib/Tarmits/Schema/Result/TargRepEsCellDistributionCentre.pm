use utf8;
package Tarmits::Schema::Result::TargRepEsCellDistributionCentre;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TargRepEsCellDistributionCentre

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<targ_rep_es_cell_distribution_centres>

=cut

__PACKAGE__->table("targ_rep_es_cell_distribution_centres");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'targ_rep_es_cell_distribution_centres_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

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
    sequence          => "targ_rep_es_cell_distribution_centres_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
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

=head2 users

Type: has_many

Related object: L<Tarmits::Schema::Result::User>

=cut

__PACKAGE__->has_many(
  "users",
  "Tarmits::Schema::Result::User",
  { "foreign.es_cell_distribution_centre_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tpUUg8FZiV+RB/6i3Gvejg

# NOTE Currently Foreign keys are missing from TargRep tables. Therefore relationships have been defined manually.
# If Foreign keys are add to this table we may see relationships defined multiple times.

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
