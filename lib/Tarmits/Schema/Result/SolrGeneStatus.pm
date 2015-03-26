use utf8;
package Tarmits::Schema::Result::SolrGeneStatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::SolrGeneStatus

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<solr_gene_statuses>

=cut

__PACKAGE__->table("solr_gene_statuses");

=head1 ACCESSORS

=head2 mi_plan_id

  data_type: 'integer'
  is_nullable: 1

=head2 marker_symbol

  data_type: 'varchar'
  is_nullable: 1
  size: 75

=head2 status_name

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 consortium

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 production_centre_name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "mi_plan_id",
  { data_type => "integer", is_nullable => 1 },
  "marker_symbol",
  { data_type => "varchar", is_nullable => 1, size => 75 },
  "status_name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "consortium",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "production_centre_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:p4qWvcd7+cuKLcTrfQ0ooA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
