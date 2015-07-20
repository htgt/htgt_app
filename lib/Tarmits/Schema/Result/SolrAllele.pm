use utf8;
package Tarmits::Schema::Result::SolrAllele;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::SolrAllele

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<solr_alleles>

=cut

__PACKAGE__->table("solr_alleles");

=head1 ACCESSORS

=head2 type

  data_type: 'text'
  is_nullable: 1

=head2 id

  data_type: 'integer'
  is_nullable: 1

=head2 product_type

  data_type: 'text'
  is_nullable: 1

=head2 allele_id

  data_type: 'integer'
  is_nullable: 1

=head2 order_from_names

  data_type: 'text'
  is_nullable: 1

=head2 order_from_urls

  data_type: 'text'
  is_nullable: 1

=head2 simple_allele_image_url

  data_type: 'text'
  is_nullable: 1

=head2 allele_image_url

  data_type: 'text'
  is_nullable: 1

=head2 genbank_file_url

  data_type: 'text'
  is_nullable: 1

=head2 mgi_accession_id

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 marker_symbol

  data_type: 'varchar'
  is_nullable: 1
  size: 75

=head2 allele_type

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 strain

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 allele_name

  data_type: 'text'
  is_nullable: 1

=head2 project_ids

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "type",
  { data_type => "text", is_nullable => 1 },
  "id",
  { data_type => "integer", is_nullable => 1 },
  "product_type",
  { data_type => "text", is_nullable => 1 },
  "allele_id",
  { data_type => "integer", is_nullable => 1 },
  "order_from_names",
  { data_type => "text", is_nullable => 1 },
  "order_from_urls",
  { data_type => "text", is_nullable => 1 },
  "simple_allele_image_url",
  { data_type => "text", is_nullable => 1 },
  "allele_image_url",
  { data_type => "text", is_nullable => 1 },
  "genbank_file_url",
  { data_type => "text", is_nullable => 1 },
  "mgi_accession_id",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "marker_symbol",
  { data_type => "varchar", is_nullable => 1, size => 75 },
  "allele_type",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "strain",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "allele_name",
  { data_type => "text", is_nullable => 1 },
  "project_ids",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:duqaAEjmlGjGaNxl2GMI6A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
