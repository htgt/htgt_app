use utf8;
package Tarmits::Schema::Result::MouseAlleleModStatusStamp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::MouseAlleleModStatusStamp

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<mouse_allele_mod_status_stamps>

=cut

__PACKAGE__->table("mouse_allele_mod_status_stamps");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'mouse_allele_mod_status_stamps_id_seq'

=head2 mouse_allele_mod_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 status_id

  data_type: 'integer'
  is_foreign_key: 1
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
    sequence          => "mouse_allele_mod_status_stamps_id_seq",
  },
  "mouse_allele_mod_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
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

=head2 mouse_allele_mod

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MouseAlleleMod>

=cut

__PACKAGE__->belongs_to(
  "mouse_allele_mod",
  "Tarmits::Schema::Result::MouseAlleleMod",
  { id => "mouse_allele_mod_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 status

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MouseAlleleModStatus>

=cut

__PACKAGE__->belongs_to(
  "status",
  "Tarmits::Schema::Result::MouseAlleleModStatus",
  { id => "status_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v710E/BD+5y1uqht/pa35A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
