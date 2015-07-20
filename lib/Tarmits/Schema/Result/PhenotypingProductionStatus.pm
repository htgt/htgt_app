use utf8;
package Tarmits::Schema::Result::PhenotypingProductionStatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::PhenotypingProductionStatus

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<phenotyping_production_statuses>

=cut

__PACKAGE__->table("phenotyping_production_statuses");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenotyping_production_statuses_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 order_by

  data_type: 'integer'
  is_nullable: 0

=head2 code

  data_type: 'varchar'
  is_nullable: 0
  size: 4

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenotyping_production_statuses_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "order_by",
  { data_type => "integer", is_nullable => 0 },
  "code",
  { data_type => "varchar", is_nullable => 0, size => 4 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 phenotyping_production_status_stamps

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypingProductionStatusStamp>

=cut

__PACKAGE__->has_many(
  "phenotyping_production_status_stamps",
  "Tarmits::Schema::Result::PhenotypingProductionStatusStamp",
  { "foreign.status_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotyping_productions

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypingProduction>

=cut

__PACKAGE__->has_many(
  "phenotyping_productions",
  "Tarmits::Schema::Result::PhenotypingProduction",
  { "foreign.status_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2015-03-17 16:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:n764bH9BonD+UK5RzOx8hQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
