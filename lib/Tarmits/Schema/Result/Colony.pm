use utf8;
package Tarmits::Schema::Result::Colony;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::Colony

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<colonies>

=cut

__PACKAGE__->table("colonies");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'colonies_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 mi_attempt_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 genotype_confirmed

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 report_to_public

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 unwanted_allele

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 unwanted_allele_description

  data_type: 'text'
  is_nullable: 1

=head2 mgi_allele_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 allele_name

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
    sequence          => "colonies_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "mi_attempt_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "genotype_confirmed",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "report_to_public",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "unwanted_allele",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "unwanted_allele_description",
  { data_type => "text", is_nullable => 1 },
  "mgi_allele_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "allele_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<colony_name_index>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("colony_name_index", ["name"]);

=head1 RELATIONS

=head2 colony_qc

Type: might_have

Related object: L<Tarmits::Schema::Result::ColonyQc>

=cut

__PACKAGE__->might_have(
  "colony_qc",
  "Tarmits::Schema::Result::ColonyQc",
  { "foreign.colony_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempt

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->belongs_to(
  "mi_attempt",
  "Tarmits::Schema::Result::MiAttempt",
  { id => "mi_attempt_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 trace_calls

Type: has_many

Related object: L<Tarmits::Schema::Result::TraceCall>

=cut

__PACKAGE__->has_many(
  "trace_calls",
  "Tarmits::Schema::Result::TraceCall",
  { "foreign.colony_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y3ISNYRPbC30/ho9KBGs2w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
