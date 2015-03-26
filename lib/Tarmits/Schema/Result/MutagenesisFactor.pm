use utf8;
package Tarmits::Schema::Result::MutagenesisFactor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::MutagenesisFactor

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<mutagenesis_factors>

=cut

__PACKAGE__->table("mutagenesis_factors");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'mutagenesis_factors_id_seq'

=head2 vector_id

  data_type: 'integer'
  is_nullable: 1

=head2 external_ref

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 nuclease

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mutagenesis_factors_id_seq",
  },
  "vector_id",
  { data_type => "integer", is_nullable => 1 },
  "external_ref",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "nuclease",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 targ_rep_genotype_primers

Type: has_many

Related object: L<Tarmits::Schema::Result::TargRepGenotypePrimer>

=cut

__PACKAGE__->has_many(
  "targ_rep_genotype_primers",
  "Tarmits::Schema::Result::TargRepGenotypePrimer",
  { "foreign.mutagenesis_factor_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nqLNz3kzJBfaqLL+/iNHjw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
