use utf8;
package Tarmits::Schema::Result::EmailTemplate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::EmailTemplate

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<email_templates>

=cut

__PACKAGE__->table("email_templates");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'email_templates_id_seq'

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 welcome_body

  data_type: 'text'
  is_nullable: 1

=head2 update_body

  data_type: 'text'
  is_nullable: 1

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
    sequence          => "email_templates_id_seq",
  },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "welcome_body",
  { data_type => "text", is_nullable => 1 },
  "update_body",
  { data_type => "text", is_nullable => 1 },
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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lwy4Qs1sfVL8OrUA+/nh1Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
