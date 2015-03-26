use utf8;
package Tarmits::Schema::Result::TraceCall;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TraceCall

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<trace_calls>

=cut

__PACKAGE__->table("trace_calls");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'trace_calls_id_seq'

=head2 colony_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 file_alignment

  data_type: 'text'
  is_nullable: 1

=head2 file_filtered_analysis_vcf

  data_type: 'text'
  is_nullable: 1

=head2 file_variant_effect_output_txt

  data_type: 'text'
  is_nullable: 1

=head2 file_reference_fa

  data_type: 'text'
  is_nullable: 1

=head2 file_mutant_fa

  data_type: 'text'
  is_nullable: 1

=head2 file_primer_reads_fa

  data_type: 'text'
  is_nullable: 1

=head2 file_alignment_data_yaml

  data_type: 'text'
  is_nullable: 1

=head2 file_trace_output

  data_type: 'text'
  is_nullable: 1

=head2 file_trace_error

  data_type: 'text'
  is_nullable: 1

=head2 file_exception_details

  data_type: 'text'
  is_nullable: 1

=head2 file_return_code

  data_type: 'integer'
  is_nullable: 1

=head2 file_merged_variants_vcf

  data_type: 'text'
  is_nullable: 1

=head2 is_het

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 0

=head2 trace_file_file_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 trace_file_content_type

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 trace_file_file_size

  data_type: 'integer'
  is_nullable: 1

=head2 trace_file_updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 exon_id

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
    sequence          => "trace_calls_id_seq",
  },
  "colony_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "file_alignment",
  { data_type => "text", is_nullable => 1 },
  "file_filtered_analysis_vcf",
  { data_type => "text", is_nullable => 1 },
  "file_variant_effect_output_txt",
  { data_type => "text", is_nullable => 1 },
  "file_reference_fa",
  { data_type => "text", is_nullable => 1 },
  "file_mutant_fa",
  { data_type => "text", is_nullable => 1 },
  "file_primer_reads_fa",
  { data_type => "text", is_nullable => 1 },
  "file_alignment_data_yaml",
  { data_type => "text", is_nullable => 1 },
  "file_trace_output",
  { data_type => "text", is_nullable => 1 },
  "file_trace_error",
  { data_type => "text", is_nullable => 1 },
  "file_exception_details",
  { data_type => "text", is_nullable => 1 },
  "file_return_code",
  { data_type => "integer", is_nullable => 1 },
  "file_merged_variants_vcf",
  { data_type => "text", is_nullable => 1 },
  "is_het",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "created_at",
  { data_type => "timestamp", is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 0 },
  "trace_file_file_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "trace_file_content_type",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "trace_file_file_size",
  { data_type => "integer", is_nullable => 1 },
  "trace_file_updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "exon_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 colony

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Colony>

=cut

__PACKAGE__->belongs_to(
  "colony",
  "Tarmits::Schema::Result::Colony",
  { id => "colony_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 trace_call_vcf_modifications

Type: has_many

Related object: L<Tarmits::Schema::Result::TraceCallVcfModification>

=cut

__PACKAGE__->has_many(
  "trace_call_vcf_modifications",
  "Tarmits::Schema::Result::TraceCallVcfModification",
  { "foreign.trace_call_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SelbyTYqJSul2ePCzULITQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
