use utf8;
package IntelliShip::SchemaClass::Result::Shipmentproduct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Shipmentproduct

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<shipmentproduct>

=cut

__PACKAGE__->table("shipmentproduct");

=head1 ACCESSORS

=head2 shipmentproductid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 shipmentid

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 13

=head2 productid

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 13

=head2 quantity

  data_type: 'integer'
  is_nullable: 1

=head2 datecreated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "shipmentproductid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "shipmentid",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 13 },
  "productid",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 13 },
  "quantity",
  { data_type => "integer", is_nullable => 1 },
  "datecreated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</shipmentproductid>

=back

=cut

__PACKAGE__->set_primary_key("shipmentproductid");

=head1 RELATIONS

=head2 productid

Type: belongs_to

Related object: L<IntelliShip::SchemaClass::Result::Product>

=cut

__PACKAGE__->belongs_to(
  "productid",
  "IntelliShip::SchemaClass::Result::Product",
  { productid => "productid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 shipmentid

Type: belongs_to

Related object: L<IntelliShip::SchemaClass::Result::Shipment>

=cut

__PACKAGE__->belongs_to(
  "shipmentid",
  "IntelliShip::SchemaClass::Result::Shipment",
  { shipmentid => "shipmentid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wKnZEqa25d71YKX+Hvcn7w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
