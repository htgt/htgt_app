use utf8;
package HTGTDB::GnmLocus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::GnmLocus

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GNM_LOCUS>

=cut

__PACKAGE__->table("mig.GNM_LOCUS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}
  sequence: 'gnm_locus_seq'

=head2 chr_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 32

=head2 chr_start

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 chr_end

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 chr_strand

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 assembly_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 type

  data_type: 'varchar2'
  is_nullable: 1
  size: 32

=head2 edit_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 check_number

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 edited_by

  data_type: 'varchar2'
  is_nullable: 1
  size: 128

=head2 created_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 creator_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 build_id

  data_type: 'numeric'
  is_foreign_key: 1
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
    sequence          => "gnm_locus_seq",
  },
  "chr_name",
  { data_type => "varchar2", is_nullable => 1, size => 32 },
  "chr_start",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "chr_end",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "chr_strand",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "assembly_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "type",
  { data_type => "varchar2", is_nullable => 1, size => 32 },
  "edit_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "check_number",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "edited_by",
  { data_type => "varchar2", is_nullable => 1, size => 128 },
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
  "build_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
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
  "build",
  "HTGTDB::GnmGeneBuild",
  { id => "build_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 gnm_exons

Type: has_many

Related object: L<HTGTDB::GnmExon>

=cut

__PACKAGE__->has_many(
  "gnm_exons",
  "HTGTDB::GnmExon",
  { "foreign.locus_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gnm_gene_build_genes

Type: has_many

Related object: L<HTGTDB::GnmGeneBuildGene>

=cut

__PACKAGE__->has_many(
  "gnm_gene_build_genes",
  "HTGTDB::GnmGeneBuildGene",
  { "foreign.locus_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gnm_transcript

Type: might_have

Related object: L<HTGTDB::GnmTranscript>

=cut

__PACKAGE__->might_have(
  "gnm_transcript",
  "HTGTDB::GnmTranscript",
  { "foreign.locus_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-04 15:29:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:B+hFnNR1A3F4RX2t4fRBdw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
