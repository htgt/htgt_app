use utf8;
package HTGTDB::GnmGeneSet;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::GnmGeneSet

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GNM_GENE_SET>

=cut

__PACKAGE__->table("mig.GNM_GENE_SET");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}
  sequence: 'gnm_gene_set_seq'

=head2 name

  data_type: 'varchar2'
  is_nullable: 1
  size: 128

=head2 description

  data_type: 'varchar2'
  is_nullable: 1
  size: 2048

=head2 timestamp

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 1
  original: {data_type => "date",default_value => \"sysdate"}

date when geneset was created

=head2 is_core_set

  data_type: 'char'
  is_nullable: 1
  size: 1

To identify the core sets (official) that contribute to the 'set count'

=head2 creator_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 check_number

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

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

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    original          => { data_type => "number", size => [38, 0] },
    sequence          => "gnm_gene_set_seq",
  },
  "name",
  { data_type => "varchar2", is_nullable => 1, size => 128 },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 2048 },
  "timestamp",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "is_core_set",
  { data_type => "char", is_nullable => 1, size => 1 },
  "creator_id",
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
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-04 15:29:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KoPrg3UwEO0k2ZGP/lL8hg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
