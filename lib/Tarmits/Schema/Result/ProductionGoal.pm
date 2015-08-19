use utf8;
package Tarmits::Schema::Result::ProductionGoal;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::ProductionGoal

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<production_goals>

=cut

__PACKAGE__->table("production_goals");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'production_goals_id_seq'

=head2 consortium_id

  data_type: 'integer'
  is_nullable: 1

=head2 year

  data_type: 'integer'
  is_nullable: 1

=head2 month

  data_type: 'integer'
  is_nullable: 1

=head2 mi_goal

  data_type: 'integer'
  is_nullable: 1

=head2 gc_goal

  data_type: 'integer'
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
    sequence          => "production_goals_id_seq",
  },
  "consortium_id",
  { data_type => "integer", is_nullable => 1 },
  "year",
  { data_type => "integer", is_nullable => 1 },
  "month",
  { data_type => "integer", is_nullable => 1 },
  "mi_goal",
  { data_type => "integer", is_nullable => 1 },
  "gc_goal",
  { data_type => "integer", is_nullable => 1 },
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

=head1 UNIQUE CONSTRAINTS

=head2 C<index_production_goals_on_consortium_id_and_year_and_month>

=over 4

=item * L</consortium_id>

=item * L</year>

=item * L</month>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "index_production_goals_on_consortium_id_and_year_and_month",
  ["consortium_id", "year", "month"],
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ikswEaBdihaEWIkT6jPFDA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
