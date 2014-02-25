use utf8;
package HTGTDB::GnmGeneBuildGene;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::GnmGeneBuildGene

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GNM_GENE_BUILD_GENE>

=cut

__PACKAGE__->table("mig.GNM_GENE_BUILD_GENE");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}
  sequence: 'gnm_gene_build_gene_seq'

=head2 build_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 locus_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 is_finished

  data_type: 'varchar2'
  is_nullable: 1
  size: 10

Output from Tony Cox's script

=head2 unique_exon_count

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 transcript_count

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 total_exon_count

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 primary_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

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

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    original          => { data_type => "number", size => [38, 0] },
    sequence          => "gnm_gene_build_gene_seq",
  },
  "build_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
  "locus_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 1,
    original       => { data_type => "number", size => [38, 0] },
  },
  "is_finished",
  { data_type => "varchar2", is_nullable => 1, size => 10 },
  "unique_exon_count",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
  "transcript_count",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
  "total_exon_count",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
  "primary_name",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
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
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 build

Type: belongs_to

Related object: L<HTGTDB::GnmGeneBuild>

=cut

__PACKAGE__->belongs_to(
  "gene_build",
  "HTGTDB::GnmGeneBuild",
  { id => "build_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 gnm_gene_2_gene_build_genes

Type: has_many

Related object: L<HTGTDB::GnmGene2GeneBuildGene>

=cut

__PACKAGE__->has_many(
  "gene_gene_build_links",
  "HTGTDB::GnmGene2GeneBuildGene",
  { "foreign.gene_build_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gnm_gene_primary_build_genes

Type: has_many

Related object: L<HTGTDB::GnmGene>

=cut

__PACKAGE__->has_many(
  "gnm_gene_primary_build_genes",
  "HTGTDB::GnmGene",
  { "foreign.primary_build_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gnm_gene_primary_ensembl_build_genes

Type: has_many

Related object: L<HTGTDB::GnmGene>

=cut

__PACKAGE__->has_many(
  "gnm_gene_primary_ensembl_build_genes",
  "HTGTDB::GnmGene",
  { "foreign.primary_ensembl_build_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gnm_gene_primary_vega_build_genes

Type: has_many

Related object: L<HTGTDB::GnmGene>

=cut

__PACKAGE__->has_many(
  "gnm_gene_primary_vega_build_genes",
  "HTGTDB::GnmGene",
  { "foreign.primary_vega_build_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gnm_transcripts

Type: has_many

Related object: L<HTGTDB::GnmTranscript>

=cut

__PACKAGE__->has_many(
  "transcripts",
  "HTGTDB::GnmTranscript",
  { "foreign.build_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 locus

Type: belongs_to

Related object: L<HTGTDB::GnmLocus>

=cut

__PACKAGE__->belongs_to(
  "locus",
  "HTGTDB::GnmLocus",
  { id => "locus_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-04 15:28:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fhmT1/aTRc719rWMRZYswg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
