use utf8;
package Tarmits::Schema::Result::TargRepSequenceAnnotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TargRepSequenceAnnotation

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<targ_rep_sequence_annotation>

=cut

__PACKAGE__->table("targ_rep_sequence_annotation");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'targ_rep_sequence_annotation_id_seq'

=head2 coordinate_start

  data_type: 'integer'
  is_nullable: 1

=head2 expected_sequence

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 actual_sequence

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 allele_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "targ_rep_sequence_annotation_id_seq",
  },
  "coordinate_start",
  { data_type => "integer", is_nullable => 1 },
  "expected_sequence",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "actual_sequence",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "allele_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m7FDOfroHX856lUT5Gv2Fg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
