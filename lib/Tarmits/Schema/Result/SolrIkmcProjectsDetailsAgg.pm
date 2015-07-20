use utf8;
package Tarmits::Schema::Result::SolrIkmcProjectsDetailsAgg;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::SolrIkmcProjectsDetailsAgg

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<solr_ikmc_projects_details_agg>

=cut

__PACKAGE__->table("solr_ikmc_projects_details_agg");

=head1 ACCESSORS

=head2 projects

  data_type: 'text'
  is_nullable: 1

=head2 pipelines

  data_type: 'text'
  is_nullable: 1

=head2 statuses

  data_type: 'text'
  is_nullable: 1

=head2 gene_id

  data_type: 'integer'
  is_nullable: 1

=head2 type

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "projects",
  { data_type => "text", is_nullable => 1 },
  "pipelines",
  { data_type => "text", is_nullable => 1 },
  "statuses",
  { data_type => "text", is_nullable => 1 },
  "gene_id",
  { data_type => "integer", is_nullable => 1 },
  "type",
  { data_type => "text", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:P3Gu8B1nJXN/DRhtRvv4nA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
