use utf8;
package Tarmits::Schema::Result::DeleterStrain;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::DeleterStrain

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<deleter_strains>

=cut

__PACKAGE__->table("deleter_strains");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'deleter_strains_id_seq'

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

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "deleter_strains_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UWyKsuTgjqhbFug1a6xo8A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
