use utf8;
package Tarmits::Schema::Result::Contact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::Contact

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<contacts>

=cut

__PACKAGE__->table("contacts");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'contacts_id_seq'

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 report_to_public

  data_type: 'boolean'
  default_value: true
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "contacts_id_seq",
  },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "report_to_public",
  { data_type => "boolean", default_value => \"true", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<index_contacts_on_email>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("index_contacts_on_email", ["email"]);

=head1 RELATIONS

=head2 notifications

Type: has_many

Related object: L<Tarmits::Schema::Result::Notification>

=cut

__PACKAGE__->has_many(
  "notifications",
  "Tarmits::Schema::Result::Notification",
  { "foreign.contact_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gfgXR/TNA0cAq+G9u4F8Eg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
