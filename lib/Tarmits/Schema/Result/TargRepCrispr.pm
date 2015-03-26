use utf8;
package Tarmits::Schema::Result::TargRepCrispr;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TargRepCrispr

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<targ_rep_crisprs>

=cut

__PACKAGE__->table("targ_rep_crisprs");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'targ_rep_crisprs_id_seq'

=head2 mutagenesis_factor_id

  data_type: 'integer'
  is_nullable: 0

=head2 sequence

  accessor: undef
  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 chr

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 start

  data_type: 'integer'
  is_nullable: 1

=head2 end

  data_type: 'integer'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "targ_rep_crisprs_id_seq",
  },
  "mutagenesis_factor_id",
  { data_type => "integer", is_nullable => 0 },
  "sequence",
  { accessor => undef, data_type => "varchar", is_nullable => 0, size => 255 },
  "chr",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "start",
  { data_type => "integer", is_nullable => 1 },
  "end",
  { data_type => "integer", is_nullable => 1 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ko3ooUseAw3Xpm6Vqg9How


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
