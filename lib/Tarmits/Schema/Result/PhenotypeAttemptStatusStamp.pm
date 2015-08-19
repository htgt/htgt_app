use utf8;
package Tarmits::Schema::Result::PhenotypeAttemptStatusStamp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::PhenotypeAttemptStatusStamp

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<phenotype_attempt_status_stamps>

=cut

__PACKAGE__->table("phenotype_attempt_status_stamps");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenotype_attempt_status_stamps_id_seq'

=head2 phenotype_attempt_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenotype_attempt_status_stamps_id_seq",
  },
  "phenotype_attempt_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<index_one_status_stamp_per_status_and_phenotype_attempt>

=over 4

=item * L</status_id>

=item * L</phenotype_attempt_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "index_one_status_stamp_per_status_and_phenotype_attempt",
  ["status_id", "phenotype_attempt_id"],
);

=head1 RELATIONS

=head2 phenotype_attempt

Type: belongs_to

Related object: L<Tarmits::Schema::Result::PhenotypeAttempt>

=cut

__PACKAGE__->belongs_to(
  "phenotype_attempt",
  "Tarmits::Schema::Result::PhenotypeAttempt",
  { id => "phenotype_attempt_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 status

Type: belongs_to

Related object: L<Tarmits::Schema::Result::PhenotypeAttemptStatus>

=cut

__PACKAGE__->belongs_to(
  "status",
  "Tarmits::Schema::Result::PhenotypeAttemptStatus",
  { id => "status_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cC4QbiP1Afsz/y9OD+EHJg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
