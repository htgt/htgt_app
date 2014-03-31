use utf8;
package HTGTDB::GnmGeneBuild;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::GnmGeneBuild

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GNM_GENE_BUILD>

=cut

__PACKAGE__->table("mig.GNM_GENE_BUILD");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}
  sequence: 'gnm_gene_build_seq'

=head2 assembly_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 name

  data_type: 'varchar2'
  is_nullable: 1
  size: 128

=head2 version

  data_type: 'varchar2'
  is_nullable: 1
  size: 128

=head2 source

  data_type: 'varchar2'
  is_nullable: 1
  size: 128

=head2 order_by

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 check_number

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 edit_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 creator_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 edited_by

  data_type: 'varchar2'
  is_nullable: 1
  size: 128

=head2 created_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    original          => { data_type => "number", size => [38, 0] },
    sequence          => "gnm_gene_build_seq",
  },
  "assembly_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 1,
    original       => { data_type => "number", size => [38, 0] },
  },
  "name",
  { data_type => "varchar2", is_nullable => 1, size => 128 },
  "version",
  { data_type => "varchar2", is_nullable => 1, size => 128 },
  "source",
  { data_type => "varchar2", is_nullable => 1, size => 128 },
  "order_by",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "check_number",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "edit_date",
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
  "edited_by",
  { data_type => "varchar2", is_nullable => 1, size => 128 },
  "created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 assembly

Type: belongs_to

Related object: L<HTGTDB::GnmAssembly>

=cut

__PACKAGE__->belongs_to(
  "assembly",
  "HTGTDB::GnmAssembly",
  { id => "assembly_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 gnm_gene_build_genes

Type: has_many

Related object: L<HTGTDB::GnmGeneBuildGene>

=cut

__PACKAGE__->has_many(
  "gnm_gene_build_genes",
  "HTGTDB::GnmGeneBuildGene",
  { "foreign.build_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gnm_loci

Type: has_many

Related object: L<HTGTDB::GnmLocus>

=cut

__PACKAGE__->has_many(
  "gnm_loci",
  "HTGTDB::GnmLocus",
  { "foreign.build_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-04 15:28:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HiS2zjtHXXSR8KcgU7d44g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
