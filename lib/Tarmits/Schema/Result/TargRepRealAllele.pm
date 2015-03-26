use utf8;
package Tarmits::Schema::Result::TargRepRealAllele;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TargRepRealAllele

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<targ_rep_real_alleles>

=cut

__PACKAGE__->table("targ_rep_real_alleles");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'targ_rep_real_alleles_id_seq'

=head2 gene_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 allele_name

  data_type: 'varchar'
  is_nullable: 0
  size: 40

=head2 allele_type

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 mgi_accession_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "targ_rep_real_alleles_id_seq",
  },
  "gene_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "allele_name",
  { data_type => "varchar", is_nullable => 0, size => 40 },
  "allele_type",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "mgi_accession_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<real_allele_logical_key>

=over 4

=item * L</gene_id>

=item * L</allele_name>

=back

=cut

__PACKAGE__->add_unique_constraint("real_allele_logical_key", ["gene_id", "allele_name"]);

=head1 RELATIONS

=head2 gene

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Gene>

=cut

__PACKAGE__->belongs_to(
  "gene",
  "Tarmits::Schema::Result::Gene",
  { id => "gene_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 mi_attempts

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.real_allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mouse_allele_mods

Type: has_many

Related object: L<Tarmits::Schema::Result::MouseAlleleMod>

=cut

__PACKAGE__->has_many(
  "mouse_allele_mods",
  "Tarmits::Schema::Result::MouseAlleleMod",
  { "foreign.real_allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_attempts

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypeAttempt>

=cut

__PACKAGE__->has_many(
  "phenotype_attempts",
  "Tarmits::Schema::Result::PhenotypeAttempt",
  { "foreign.real_allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 targ_rep_es_cells

Type: has_many

Related object: L<Tarmits::Schema::Result::TargRepEsCell>

=cut

__PACKAGE__->has_many(
  "targ_rep_es_cells",
  "Tarmits::Schema::Result::TargRepEsCell",
  { "foreign.real_allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NNr7kaceAmQZbhlyFVDHBg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
