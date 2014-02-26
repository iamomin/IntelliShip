use utf8;
package IntelliShip::SchemaClass::Result::Product;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Product

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

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

=head1 TABLE: C<product>

=cut

__PACKAGE__->table("product");

=head1 ACCESSORS

=head2 productid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 coid

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 1
  size: 13

=head2 productquantity

  data_type: 'integer'
  is_nullable: 1

=head2 shippedquantity

  data_type: 'integer'
  is_nullable: 1

=head2 unittypeid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 weighttypeid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 productprice

  data_type: 'double precision'
  is_nullable: 1

=head2 productdescr

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 productweight

  data_type: 'double precision'
  is_nullable: 1

=head2 partnumber

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 datecreated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 statusid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 linenum

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=head2 dimlength

  data_type: 'double precision'
  is_nullable: 1

=head2 dimwidth

  data_type: 'double precision'
  is_nullable: 1

=head2 dimheight

  data_type: 'double precision'
  is_nullable: 1

=head2 hazardous

  data_type: 'integer'
  is_nullable: 1

=head2 serialnumber

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 producttype

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 nmfc

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 class

  data_type: 'double precision'
  is_nullable: 1

=head2 decval

  data_type: 'double precision'
  is_nullable: 1

=head2 frtins

  data_type: 'double precision'
  is_nullable: 1

=head2 dimweight

  data_type: 'double precision'
  is_nullable: 1

=head2 density

  data_type: 'double precision'
  is_nullable: 1

=head2 unitofmeasure

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 boxnum

  data_type: 'integer'
  is_nullable: 1

=head2 originalcoid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 dryicewt

  data_type: 'integer'
  is_nullable: 1

=head2 consolidationtype

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "productid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "coid",
  { data_type => "char", is_foreign_key => 1, is_nullable => 1, size => 13 },
  "productquantity",
  { data_type => "integer", is_nullable => 1 },
  "shippedquantity",
  { data_type => "integer", is_nullable => 1 },
  "unittypeid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "weighttypeid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "productprice",
  { data_type => "double precision", is_nullable => 1 },
  "productdescr",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "productweight",
  { data_type => "double precision", is_nullable => 1 },
  "partnumber",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "datecreated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "statusid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "linenum",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "dimlength",
  { data_type => "double precision", is_nullable => 1 },
  "dimwidth",
  { data_type => "double precision", is_nullable => 1 },
  "dimheight",
  { data_type => "double precision", is_nullable => 1 },
  "hazardous",
  { data_type => "integer", is_nullable => 1 },
  "serialnumber",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "producttype",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "nmfc",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "class",
  { data_type => "double precision", is_nullable => 1 },
  "decval",
  { data_type => "double precision", is_nullable => 1 },
  "frtins",
  { data_type => "double precision", is_nullable => 1 },
  "dimweight",
  { data_type => "double precision", is_nullable => 1 },
  "density",
  { data_type => "double precision", is_nullable => 1 },
  "unitofmeasure",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "boxnum",
  { data_type => "integer", is_nullable => 1 },
  "originalcoid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "dryicewt",
  { data_type => "integer", is_nullable => 1 },
  "consolidationtype",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</productid>

=back

=cut

__PACKAGE__->set_primary_key("productid");

=head1 RELATIONS

=head2 coid

Type: belongs_to

Related object: L<IntelliShip::SchemaClass::Result::Co>

=cut

__PACKAGE__->belongs_to(
  "coid",
  "IntelliShip::SchemaClass::Result::Co",
  { coid => "coid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 shipmentproducts

Type: has_many

Related object: L<IntelliShip::SchemaClass::Result::Shipmentproduct>

=cut

__PACKAGE__->has_many(
  "shipmentproducts",
  "IntelliShip::SchemaClass::Result::Shipmentproduct",
  { "foreign.productid" => "self.productid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 statusid

Type: belongs_to

Related object: L<IntelliShip::SchemaClass::Result::Productstatus>

=cut

__PACKAGE__->belongs_to(
  "statusid",
  "IntelliShip::SchemaClass::Result::Productstatus",
  { productstatusid => "statusid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 unittypeid

Type: belongs_to

Related object: L<IntelliShip::SchemaClass::Result::Unittype>

=cut

__PACKAGE__->belongs_to(
  "unittypeid",
  "IntelliShip::SchemaClass::Result::Unittype",
  { unittypeid => "unittypeid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 weighttypeid

Type: belongs_to

Related object: L<IntelliShip::SchemaClass::Result::Weighttype>

=cut

__PACKAGE__->belongs_to(
  "weighttypeid",
  "IntelliShip::SchemaClass::Result::Weighttype",
  { weighttypeid => "weighttypeid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NHu9YbkjZB9V8ll/3OWHlA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
