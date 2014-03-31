use utf8;
package HTGTDB::GnmGene;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::GnmGene

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GNM_GENE>

=cut

__PACKAGE__->table("mig.GNM_GENE");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}
  sequence: 'gnm_gene_seq'

=head2 ncbi_taxon

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 primary_build_gene_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 is_valid

  data_type: 'numeric'
  default_value: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

USED FOR DELETING GENES WITHOUT ACTUALLY REMOVING THEM

=head2 primary_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 512

=head2 primary_vega_build_gene_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 primary_ensembl_build_gene_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 primary_name_source

  data_type: 'varchar2'
  is_nullable: 1
  size: 30

=head2 new_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 512

=head2 old_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 512

=head2 in_current_ensembl

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 in_current_vega

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 check_number

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 edited_by

  data_type: 'varchar2'
  is_nullable: 1
  size: 128

=head2 edit_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 created_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 creator_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 uc_primary_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 512

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    original          => { data_type => "number", size => [38, 0] },
    sequence          => "gnm_gene_seq",
  },
  "ncbi_taxon",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
  "primary_build_gene_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 1,
    original       => { data_type => "number", size => [38, 0] },
  },
  "is_valid",
  {
    data_type => "numeric",
    default_value => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "primary_name",
  { data_type => "varchar2", is_nullable => 1, size => 512 },
  "primary_vega_build_gene_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 1,
    original       => { data_type => "number", size => [38, 0] },
  },
  "primary_ensembl_build_gene_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 1,
    original       => { data_type => "number", size => [38, 0] },
  },
  "primary_name_source",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "new_name",
  { data_type => "varchar2", is_nullable => 1, size => 512 },
  "old_name",
  { data_type => "varchar2", is_nullable => 1, size => 512 },
  "in_current_ensembl",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "in_current_vega",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "check_number",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "edited_by",
  { data_type => "varchar2", is_nullable => 1, size => 128 },
  "edit_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "creator_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "uc_primary_name",
  { data_type => "varchar2", is_nullable => 1, size => 512 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 gnm_gene_2_gene_build_genes

Type: has_many

Related object: L<HTGTDB::GnmGene2GeneBuildGene>

=cut

__PACKAGE__->has_many(
  "gnm_gene_2_gene_build_genes",
  "HTGTDB::GnmGene2GeneBuildGene",
  { "foreign.gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 primary_build_gene

Type: belongs_to

Related object: L<HTGTDB::GnmGeneBuildGene>

=cut

__PACKAGE__->belongs_to(
  "primary_build_gene",
  "HTGTDB::GnmGeneBuildGene",
  { id => "primary_build_gene_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 primary_ensembl_build_gene

Type: belongs_to

Related object: L<HTGTDB::GnmGeneBuildGene>

=cut

__PACKAGE__->belongs_to(
  "primary_ensembl_build_gene",
  "HTGTDB::GnmGeneBuildGene",
  { id => "primary_ensembl_build_gene_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 primary_vega_build_gene

Type: belongs_to

Related object: L<HTGTDB::GnmGeneBuildGene>

=cut

__PACKAGE__->belongs_to(
  "primary_vega_build_gene",
  "HTGTDB::GnmGeneBuildGene",
  { id => "primary_vega_build_gene_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-04 15:28:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mpiPi+Lw2zbVtY6UOfHXqw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
