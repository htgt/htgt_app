use utf8;
package HTGTDB::GnmExon;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::GnmExon

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GNM_EXON>

=cut

__PACKAGE__->table("mig.GNM_EXON");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}
  sequence: 'gnm_exon_seq'

=head2 locus_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 transcript_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 phase

  data_type: 'integer'
  is_nullable: 1
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
    sequence          => "gnm_exon_seq",
  },
  "locus_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 1,
    original       => { data_type => "number", size => [38, 0] },
  },
  "transcript_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 1,
    original       => { data_type => "number", size => [38, 0] },
  },
  "phase",
  {
    data_type   => "integer",
    is_nullable => 1,
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

=head2 transcript

Type: belongs_to

Related object: L<HTGTDB::GnmTranscript>

=cut

__PACKAGE__->belongs_to(
  "transcript",
  "HTGTDB::GnmTranscript",
  { id => "transcript_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-04 15:28:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DatKwODsGToG/Tq5mnbJcw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
