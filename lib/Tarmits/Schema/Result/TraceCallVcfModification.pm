use utf8;
package Tarmits::Schema::Result::TraceCallVcfModification;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TraceCallVcfModification

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<trace_call_vcf_modifications>

=cut

__PACKAGE__->table("trace_call_vcf_modifications");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'trace_call_vcf_modifications_id_seq'

=head2 trace_call_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 mod_type

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 chr

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 start

  data_type: 'integer'
  is_nullable: 0

=head2 end

  data_type: 'integer'
  is_nullable: 0

=head2 ref_seq

  data_type: 'text'
  is_nullable: 0

=head2 alt_seq

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "trace_call_vcf_modifications_id_seq",
  },
  "trace_call_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "mod_type",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "chr",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "start",
  { data_type => "integer", is_nullable => 0 },
  "end",
  { data_type => "integer", is_nullable => 0 },
  "ref_seq",
  { data_type => "text", is_nullable => 0 },
  "alt_seq",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  { data_type => "timestamp", is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 trace_call

Type: belongs_to

Related object: L<Tarmits::Schema::Result::TraceCall>

=cut

__PACKAGE__->belongs_to(
  "trace_call",
  "Tarmits::Schema::Result::TraceCall",
  { id => "trace_call_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qHMPImIxgkNb5SPxBUaOmQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
