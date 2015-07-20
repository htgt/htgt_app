use utf8;
package Tarmits::Schema::Result::TargRepEsCellMutationType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TargRepEsCellMutationType

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<targ_rep_es_cell_mutation_types>

=cut

__PACKAGE__->table("targ_rep_es_cell_mutation_types");

=head1 ACCESSORS

=head2 es_cell_id

  data_type: 'integer'
  is_nullable: 1

=head2 mutation_type

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "es_cell_id",
  { data_type => "integer", is_nullable => 1 },
  "mutation_type",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bBEOGM+JhPhTUFXa3S05yg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
