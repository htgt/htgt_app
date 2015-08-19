use utf8;
package Tarmits::Schema::Result::SolrGene;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::SolrGene

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<solr_genes>

=cut

__PACKAGE__->table("solr_genes");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 1

=head2 type

  data_type: 'text'
  is_nullable: 1

=head2 allele_id

  data_type: 'text'
  is_nullable: 1

=head2 consortium

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 production_centre

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 effective_date

  data_type: 'timestamp'
  is_nullable: 1

=head2 mgi_accession_id

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 project_ids

  data_type: 'text'
  is_nullable: 1

=head2 project_statuses

  data_type: 'text'
  is_nullable: 1

=head2 project_pipelines

  data_type: 'text'
  is_nullable: 1

=head2 vector_project_ids

  data_type: 'text'
  is_nullable: 1

=head2 vector_project_statuses

  data_type: 'text'
  is_nullable: 1

=head2 marker_symbol

  data_type: 'varchar'
  is_nullable: 1
  size: 75

=head2 marker_type

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 1 },
  "type",
  { data_type => "text", is_nullable => 1 },
  "allele_id",
  { data_type => "text", is_nullable => 1 },
  "consortium",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "production_centre",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "effective_date",
  { data_type => "timestamp", is_nullable => 1 },
  "mgi_accession_id",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "project_ids",
  { data_type => "text", is_nullable => 1 },
  "project_statuses",
  { data_type => "text", is_nullable => 1 },
  "project_pipelines",
  { data_type => "text", is_nullable => 1 },
  "vector_project_ids",
  { data_type => "text", is_nullable => 1 },
  "vector_project_statuses",
  { data_type => "text", is_nullable => 1 },
  "marker_symbol",
  { data_type => "varchar", is_nullable => 1, size => 75 },
  "marker_type",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QFTpsXoDmeHIlzIhk9o18A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
