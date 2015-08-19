use utf8;
package Tarmits::Schema::Result::Strain;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::Strain

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<strains>

=cut

__PACKAGE__->table("strains");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'strains_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 mgi_strain_accession_id

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 mgi_strain_name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "strains_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "mgi_strain_accession_id",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "mgi_strain_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<index_strains_on_name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("index_strains_on_name", ["name"]);

=head1 RELATIONS

=head2 mi_attempts_blast_strains

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_blast_strains",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.blast_strain_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempts_colony_background_strains

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_colony_background_strains",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.colony_background_strain_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempts_test_cross_strains

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_test_cross_strains",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.test_cross_strain_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mouse_allele_mods_colony_background_strains

Type: has_many

Related object: L<Tarmits::Schema::Result::MouseAlleleMod>

=cut

__PACKAGE__->has_many(
  "mouse_allele_mods_colony_background_strains",
  "Tarmits::Schema::Result::MouseAlleleMod",
  { "foreign.colony_background_strain_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mouse_allele_mods_deleter_strains

Type: has_many

Related object: L<Tarmits::Schema::Result::MouseAlleleMod>

=cut

__PACKAGE__->has_many(
  "mouse_allele_mods_deleter_strains",
  "Tarmits::Schema::Result::MouseAlleleMod",
  { "foreign.deleter_strain_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_attempts

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypeAttempt>

=cut

__PACKAGE__->has_many(
  "phenotype_attempts",
  "Tarmits::Schema::Result::PhenotypeAttempt",
  { "foreign.colony_background_strain_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cC93/P8/Nr/UVoIKw2rnmA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
