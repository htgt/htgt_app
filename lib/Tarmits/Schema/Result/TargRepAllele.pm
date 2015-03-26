use utf8;
package Tarmits::Schema::Result::TargRepAllele;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TargRepAllele

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<targ_rep_alleles>

=cut

__PACKAGE__->table("targ_rep_alleles");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'targ_rep_alleles_id_seq'

=head2 gene_id

  data_type: 'integer'
  is_nullable: 1

=head2 assembly

  data_type: 'varchar'
  default_value: 'GRCm38'
  is_nullable: 0
  size: 255

=head2 chromosome

  data_type: 'varchar'
  is_nullable: 0
  size: 2

=head2 strand

  data_type: 'varchar'
  is_nullable: 0
  size: 1

=head2 homology_arm_start

  data_type: 'integer'
  is_nullable: 1

=head2 homology_arm_end

  data_type: 'integer'
  is_nullable: 1

=head2 loxp_start

  data_type: 'integer'
  is_nullable: 1

=head2 loxp_end

  data_type: 'integer'
  is_nullable: 1

=head2 cassette_start

  data_type: 'integer'
  is_nullable: 1

=head2 cassette_end

  data_type: 'integer'
  is_nullable: 1

=head2 cassette

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 backbone

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 subtype_description

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 floxed_start_exon

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 floxed_end_exon

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 project_design_id

  data_type: 'integer'
  is_nullable: 1

=head2 reporter

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 mutation_method_id

  data_type: 'integer'
  is_nullable: 1

=head2 mutation_type_id

  data_type: 'integer'
  is_nullable: 1

=head2 mutation_subtype_id

  data_type: 'integer'
  is_nullable: 1

=head2 cassette_type

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 0

=head2 intron

  data_type: 'integer'
  is_nullable: 1

=head2 type

  data_type: 'varchar'
  default_value: 'TargRep::TargetedAllele'
  is_nullable: 1
  size: 255

=head2 has_issue

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 issue_description

  data_type: 'text'
  is_nullable: 1

=head2 sequence

  accessor: undef
  data_type: 'text'
  is_nullable: 1

=head2 taqman_critical_del_assay_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 taqman_upstream_del_assay_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 taqman_downstream_del_assay_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 wildtype_oligos_sequence

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
    sequence          => "targ_rep_alleles_id_seq",
  },
  "gene_id",
  { data_type => "integer", is_nullable => 1 },
  "assembly",
  {
    data_type => "varchar",
    default_value => "GRCm38",
    is_nullable => 0,
    size => 255,
  },
  "chromosome",
  { data_type => "varchar", is_nullable => 0, size => 2 },
  "strand",
  { data_type => "varchar", is_nullable => 0, size => 1 },
  "homology_arm_start",
  { data_type => "integer", is_nullable => 1 },
  "homology_arm_end",
  { data_type => "integer", is_nullable => 1 },
  "loxp_start",
  { data_type => "integer", is_nullable => 1 },
  "loxp_end",
  { data_type => "integer", is_nullable => 1 },
  "cassette_start",
  { data_type => "integer", is_nullable => 1 },
  "cassette_end",
  { data_type => "integer", is_nullable => 1 },
  "cassette",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "backbone",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "subtype_description",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "floxed_start_exon",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "floxed_end_exon",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "project_design_id",
  { data_type => "integer", is_nullable => 1 },
  "reporter",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "mutation_method_id",
  { data_type => "integer", is_nullable => 1 },
  "mutation_type_id",
  { data_type => "integer", is_nullable => 1 },
  "mutation_subtype_id",
  { data_type => "integer", is_nullable => 1 },
  "cassette_type",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "created_at",
  { data_type => "timestamp", is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 0 },
  "intron",
  { data_type => "integer", is_nullable => 1 },
  "type",
  {
    data_type => "varchar",
    default_value => "TargRep::TargetedAllele",
    is_nullable => 1,
    size => 255,
  },
  "has_issue",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "issue_description",
  { data_type => "text", is_nullable => 1 },
  "sequence",
  { accessor => undef, data_type => "text", is_nullable => 1 },
  "taqman_critical_del_assay_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "taqman_upstream_del_assay_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "taqman_downstream_del_assay_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "wildtype_oligos_sequence",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 mi_attempts

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mouse_allele_mods

Type: has_many

Related object: L<Tarmits::Schema::Result::MouseAlleleMod>

=cut

__PACKAGE__->has_many(
  "mouse_allele_mods",
  "Tarmits::Schema::Result::MouseAlleleMod",
  { "foreign.allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_attempts

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypeAttempt>

=cut

__PACKAGE__->has_many(
  "phenotype_attempts",
  "Tarmits::Schema::Result::PhenotypeAttempt",
  { "foreign.allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 targ_rep_allele_sequence_annotations

Type: has_many

Related object: L<Tarmits::Schema::Result::TargRepAlleleSequenceAnnotation>

=cut

__PACKAGE__->has_many(
  "targ_rep_allele_sequence_annotations",
  "Tarmits::Schema::Result::TargRepAlleleSequenceAnnotation",
  { "foreign.allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 targ_rep_genotype_primers

Type: has_many

Related object: L<Tarmits::Schema::Result::TargRepGenotypePrimer>

=cut

__PACKAGE__->has_many(
  "targ_rep_genotype_primers",
  "Tarmits::Schema::Result::TargRepGenotypePrimer",
  { "foreign.allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/6cKQiL2PaW/fxwjaaKNLA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
# NOTE Currently Foreign keys are missing from TargRep tables. Therefore relationships have been defined manually.
# If Foreign keys are add to this table we may see relationships defined multiple times.

__PACKAGE__->has_many(
  "targ_rep_es_cells",
  "Tarmits::Schema::Result::TargRepEsCell",
  { "foreign.allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 genbank_files

Type: has_many

Related object: L<Tarmits::Schema::Result::GenbankFile>

=cut

__PACKAGE__->has_many(
  "targ_rep_genbank_files",
  "Tarmits::Schema::Result::TargRepGenbankFile",
  { "foreign.allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 targeting_vectors

Type: has_many

Related object: L<Tarmits::Schema::Result::TargetingVector>

=cut

__PACKAGE__->has_many(
  "targ_rep_targeting_vectors",
  "Tarmits::Schema::Result::TargRepTargetingVector",
  { "foreign.allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gene

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Gene>

=cut

__PACKAGE__->belongs_to(
  "gene",
  "Tarmits::Schema::Result::Gene",
  { id => "gene_id" },
);

=head2 mutation_method

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MutationMethod>

=cut

__PACKAGE__->belongs_to(
  "targ_rep_mutation_method",
  "Tarmits::Schema::Result::TargRepMutationMethod",
  { id => "mutation_method_id" },
);

=head2 mutation_type

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MutationType>

=cut

__PACKAGE__->belongs_to(
  "targ_rep_mutation_type",
  "Tarmits::Schema::Result::TargRepMutationType",
  { id => "mutation_type_id" },
);

=head2 mutation_method

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MutationSubtype>

=cut

__PACKAGE__->belongs_to(
  "targ_rep_mutation_subtype",
  "Tarmits::Schema::Result::TargRepMutationSubtype",
  { id => "mutation_subtype_id" },
);

sub mutation_type_name {
    my $self = shift;

    return $self->targ_rep_mutation_type->name;
}

sub mutation_subtype_name {
    my $self = shift;
    return unless $self->targ_rep_mutation_subtype;
    return $self->targ_rep_mutation_subtype->name;
}

sub mutation_method_name {
    my $self = shift;

    return $self->targ_rep_mutation_method->name;
}
1;
