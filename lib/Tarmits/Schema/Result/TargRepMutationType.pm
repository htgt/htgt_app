use utf8;
package Tarmits::Schema::Result::TargRepMutationType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TargRepMutationType

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<targ_rep_mutation_types>

=cut

__PACKAGE__->table("targ_rep_mutation_types");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'targ_rep_mutation_types_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 code

  data_type: 'varchar'
  is_nullable: 0
  size: 100

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
    sequence          => "targ_rep_mutation_types_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "code",
  { data_type => "varchar", is_nullable => 0, size => 100 },
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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MLH2O0A2PeJLZVYSnoKEjQ

# NOTE Currently Foreign keys are missing from TargRep tables. Therefore relationships have been defined manually.
# If Foreign keys are add to this table we may see relationships defined multiple times.

__PACKAGE__->has_many(
  "targ_rep_alleles",
  "Tarmits::Schema::Result::TargRepAllele",
  { "foreign.mutation_type_id" => "self.id" },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
