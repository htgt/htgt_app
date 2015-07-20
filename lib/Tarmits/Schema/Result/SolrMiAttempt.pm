use utf8;
package Tarmits::Schema::Result::SolrMiAttempt;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::SolrMiAttempt

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<solr_mi_attempts>

=cut

__PACKAGE__->table("solr_mi_attempts");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 1

=head2 product_type

  data_type: 'text'
  is_nullable: 1

=head2 type

  data_type: 'text'
  is_nullable: 1

=head2 colony_name

  data_type: 'varchar'
  is_nullable: 1
  size: 125

=head2 marker_symbol

  data_type: 'varchar'
  is_nullable: 1
  size: 75

=head2 es_cell_name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 allele_id

  data_type: 'integer'
  is_nullable: 1

=head2 mgi_accession_id

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 production_centre

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 strain

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 genbank_file_url

  data_type: 'text'
  is_nullable: 1

=head2 allele_image_url

  data_type: 'text'
  is_nullable: 1

=head2 simple_allele_image_url

  data_type: 'text'
  is_nullable: 1

=head2 allele_type

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 project_ids

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 current_pa_status

  data_type: 'text'
  is_nullable: 1

=head2 allele_name

  data_type: 'text'
  is_nullable: 1

=head2 order_from_names

  data_type: 'text'
  is_nullable: 1

=head2 order_from_urls

  data_type: 'text'
  is_nullable: 1

=head2 best_status_pa_cre_ex_not_required

  data_type: 'text'
  is_nullable: 1

=head2 best_status_pa_cre_ex_required

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 1 },
  "product_type",
  { data_type => "text", is_nullable => 1 },
  "type",
  { data_type => "text", is_nullable => 1 },
  "colony_name",
  { data_type => "varchar", is_nullable => 1, size => 125 },
  "marker_symbol",
  { data_type => "varchar", is_nullable => 1, size => 75 },
  "es_cell_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "allele_id",
  { data_type => "integer", is_nullable => 1 },
  "mgi_accession_id",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "production_centre",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "strain",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "genbank_file_url",
  { data_type => "text", is_nullable => 1 },
  "allele_image_url",
  { data_type => "text", is_nullable => 1 },
  "simple_allele_image_url",
  { data_type => "text", is_nullable => 1 },
  "allele_type",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "project_ids",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "current_pa_status",
  { data_type => "text", is_nullable => 1 },
  "allele_name",
  { data_type => "text", is_nullable => 1 },
  "order_from_names",
  { data_type => "text", is_nullable => 1 },
  "order_from_urls",
  { data_type => "text", is_nullable => 1 },
  "best_status_pa_cre_ex_not_required",
  { data_type => "text", is_nullable => 1 },
  "best_status_pa_cre_ex_required",
  { data_type => "text", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:t7Miz/mEf2B31/zMIt2c+w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
