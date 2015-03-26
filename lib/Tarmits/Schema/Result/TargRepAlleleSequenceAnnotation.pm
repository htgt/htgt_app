use utf8;
package Tarmits::Schema::Result::TargRepAlleleSequenceAnnotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TargRepAlleleSequenceAnnotation

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<targ_rep_allele_sequence_annotations>

=cut

__PACKAGE__->table("targ_rep_allele_sequence_annotations");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'targ_rep_allele_sequence_annotations_id_seq'

=head2 mutation_type

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 expected

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 actual

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 oligos_start_coordinate

  data_type: 'integer'
  is_nullable: 1

=head2 oligos_end_coordinate

  data_type: 'integer'
  is_nullable: 1

=head2 mutation_length

  data_type: 'integer'
  is_nullable: 1

=head2 genomic_start_coordinate

  data_type: 'integer'
  is_nullable: 1

=head2 genomic_end_coordinate

  data_type: 'integer'
  is_nullable: 1

=head2 allele_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "targ_rep_allele_sequence_annotations_id_seq",
  },
  "mutation_type",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "expected",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "actual",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "oligos_start_coordinate",
  { data_type => "integer", is_nullable => 1 },
  "oligos_end_coordinate",
  { data_type => "integer", is_nullable => 1 },
  "mutation_length",
  { data_type => "integer", is_nullable => 1 },
  "genomic_start_coordinate",
  { data_type => "integer", is_nullable => 1 },
  "genomic_end_coordinate",
  { data_type => "integer", is_nullable => 1 },
  "allele_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 allele

Type: belongs_to

Related object: L<Tarmits::Schema::Result::TargRepAllele>

=cut

__PACKAGE__->belongs_to(
  "allele",
  "Tarmits::Schema::Result::TargRepAllele",
  { id => "allele_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pNvSkMF23Cz/DKK/r2ACEA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
