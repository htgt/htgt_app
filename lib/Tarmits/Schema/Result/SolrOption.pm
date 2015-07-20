use utf8;
package Tarmits::Schema::Result::SolrOption;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::SolrOption

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<solr_options>

=cut

__PACKAGE__->table("solr_options");

=head1 ACCESSORS

=head2 key

  data_type: 'text'
  is_nullable: 1

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 mode

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "key",
  { data_type => "text", is_nullable => 1 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "mode",
  { data_type => "text", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xN2EpswLadt5d3vNFCMalw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
