use utf8;
package Tarmits::Schema::Result::TrackingGoal;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TrackingGoal

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<tracking_goals>

=cut

__PACKAGE__->table("tracking_goals");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tracking_goals_id_seq'

=head2 production_centre_id

  data_type: 'integer'
  is_nullable: 1

=head2 date

  data_type: 'date'
  is_nullable: 1

=head2 goal_type

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 goal

  data_type: 'integer'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 0

=head2 consortium_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tracking_goals_id_seq",
  },
  "production_centre_id",
  { data_type => "integer", is_nullable => 1 },
  "date",
  { data_type => "date", is_nullable => 1 },
  "goal_type",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "goal",
  { data_type => "integer", is_nullable => 1 },
  "created_at",
  { data_type => "timestamp", is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 0 },
  "consortium_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PIZUUlEwXFIfdZCLLR2F3w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
