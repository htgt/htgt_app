use utf8;
package Tarmits::Schema::Result::SolrCentreMap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::SolrCentreMap

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<solr_centre_map>

=cut

__PACKAGE__->table("solr_centre_map");

=head1 ACCESSORS

=head2 centre_name

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 pref

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 def

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "centre_name",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "pref",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "def",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:muPDYWmKSOFWNjWbEoCUaA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
