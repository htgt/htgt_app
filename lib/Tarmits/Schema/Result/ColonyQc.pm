use utf8;
package Tarmits::Schema::Result::ColonyQc;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::ColonyQc

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<colony_qcs>

=cut

__PACKAGE__->table("colony_qcs");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'colony_qcs_id_seq'

=head2 colony_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 qc_southern_blot

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_five_prime_lr_pcr

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_five_prime_cassette_integrity

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_tv_backbone_assay

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_neo_count_qpcr

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_lacz_count_qpcr

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_neo_sr_pcr

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_loa_qpcr

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_homozygous_loa_sr_pcr

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_lacz_sr_pcr

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_mutant_specific_sr_pcr

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_loxp_confirmation

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_three_prime_lr_pcr

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_critical_region_qpcr

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_loxp_srpcr

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 qc_loxp_srpcr_and_sequencing

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "colony_qcs_id_seq",
  },
  "colony_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "qc_southern_blot",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_five_prime_lr_pcr",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_five_prime_cassette_integrity",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_tv_backbone_assay",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_neo_count_qpcr",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_lacz_count_qpcr",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_neo_sr_pcr",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_loa_qpcr",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_homozygous_loa_sr_pcr",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_lacz_sr_pcr",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_mutant_specific_sr_pcr",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_loxp_confirmation",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_three_prime_lr_pcr",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_critical_region_qpcr",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_loxp_srpcr",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "qc_loxp_srpcr_and_sequencing",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<index_colony_qcs_on_colony_id>

=over 4

=item * L</colony_id>

=back

=cut

__PACKAGE__->add_unique_constraint("index_colony_qcs_on_colony_id", ["colony_id"]);

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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WL2hY8j+pEHxG5qCUj1aXw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
