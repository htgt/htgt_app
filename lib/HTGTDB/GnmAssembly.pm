use utf8;
package HTGTDB::GnmAssembly;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::GnmAssembly

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GNM_ASSEMBLY>

=cut

__PACKAGE__->table("mig.GNM_ASSEMBLY");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}
  sequence: 'gnm_assembly_seq'

=head2 ncbi_taxon

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 species_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 128

=head2 name

  data_type: 'varchar2'
  is_nullable: 1
  size: 2000

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
    sequence          => "gnm_assembly_seq",
  },
  "ncbi_taxon",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "species_name",
  { data_type => "varchar2", is_nullable => 1, size => 128 },
  "name",
  { data_type => "varchar2", is_nullable => 1, size => 2000 },
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

=head1 RELATIONS

=head2 gnm_genes_build

Type: has_many

Related object: L<HTGTDB::GnmGeneBuild>

=cut

__PACKAGE__->has_many(
  "gnm_genes_build",
  "HTGTDB::GnmGeneBuild",
  { "foreign.assembly_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-04 15:28:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TlXXmtnR54dO9pZbpkibrg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
