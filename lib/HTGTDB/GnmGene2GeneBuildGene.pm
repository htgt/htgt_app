use utf8;
package HTGTDB::GnmGene2GeneBuildGene;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::GnmGene2GeneBuildGene

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GNM_GENE_2_GENE_BUILD_GENE>

=cut

__PACKAGE__->table("mig.GNM_GENE_2_GENE_BUILD_GENE");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}
  sequence: 'gnm_gene_2_gene_build_gene_seq'

=head2 gene_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 gene_build_gene_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 edit_date

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 1
  original: {data_type => "date",default_value => \"sysdate"}

=head2 reasoning

  data_type: 'varchar2'
  is_nullable: 1
  size: 1024

=head2 is_valid

  data_type: 'numeric'
  default_value: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

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

=head2 check_number

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    original          => { data_type => "number", size => [38, 0] },
    sequence          => "gnm_gene_2_gene_build_gene_seq",
  },
  "gene_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 1,
    original       => { data_type => "number", size => [38, 0] },
  },
  "gene_build_gene_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 1,
    original       => { data_type => "number", size => [38, 0] },
  },
  "edit_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "reasoning",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "is_valid",
  {
    data_type => "numeric",
    default_value => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
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
  "check_number",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<gnm_gene_2_gene_build_gene_u01>

=over 4

=item * L</gene_id>

=item * L</gene_build_gene_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "gnm_gene_2_gene_build_gene_u01",
  ["gene_id", "gene_build_gene_id"],
);

=head1 RELATIONS

=head2 gene

Type: belongs_to

Related object: L<HTGTDB::GnmGene>

=cut

__PACKAGE__->belongs_to(
  "gene",
  "HTGTDB::GnmGene",
  { id => "gene_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 gene_build_gene

Type: belongs_to

Related object: L<HTGTDB::GnmGeneBuildGene>

=cut

__PACKAGE__->belongs_to(
  "gene_build_gene",
  "HTGTDB::GnmGeneBuildGene",
  { id => "gene_build_gene_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-04 15:28:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XcewLaSgYApDKAQrw4GvJA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
