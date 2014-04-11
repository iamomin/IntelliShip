use utf8;
package IntelliShip::SchemaClass::Result::Shipmentpackage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Shipmentpackage

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

=head1 TABLE: C<shipmentpackage>

=cut

__PACKAGE__->table("shipmentpackage");

=head1 ACCESSORS

=head2 shipmentpackageid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 shipmentid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 dimtypeid

  data_type: 'integer'
  is_nullable: 1

=head2 weighttypeid

  data_type: 'integer'
  is_nullable: 1

=head2 unittypeid

  data_type: 'integer'
  is_nullable: 1

=head2 quantity

  data_type: 'integer'
  is_nullable: 1

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 weight

  data_type: 'double precision'
  is_nullable: 1

=head2 dimweight

  data_type: 'double precision'
  is_nullable: 1

=head2 dimlength

  data_type: 'double precision'
  is_nullable: 1

=head2 dimwidth

  data_type: 'double precision'
  is_nullable: 1

=head2 dimheight

  data_type: 'double precision'
  is_nullable: 1

=head2 density

  data_type: 'double precision'
  is_nullable: 1

=head2 decval

  data_type: 'double precision'
  is_nullable: 1

=head2 frtins

  data_type: 'double precision'
  is_nullable: 1

=head2 nmfc

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 class

  data_type: 'double precision'
  is_nullable: 1

=head2 partnumber

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 originalcoid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 unitofmeasure

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 boxnum

  data_type: 'integer'
  is_nullable: 1

=head2 productquantity

  data_type: 'integer'
  is_nullable: 1

=head2 dryicewt

  data_type: 'integer'
  is_nullable: 1

=head2 consolidationtype

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "shipmentpackageid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "shipmentid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "dimtypeid",
  { data_type => "integer", is_nullable => 1 },
  "weighttypeid",
  { data_type => "integer", is_nullable => 1 },
  "unittypeid",
  { data_type => "integer", is_nullable => 1 },
  "quantity",
  { data_type => "integer", is_nullable => 1 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "weight",
  { data_type => "double precision", is_nullable => 1 },
  "dimweight",
  { data_type => "double precision", is_nullable => 1 },
  "dimlength",
  { data_type => "double precision", is_nullable => 1 },
  "dimwidth",
  { data_type => "double precision", is_nullable => 1 },
  "dimheight",
  { data_type => "double precision", is_nullable => 1 },
  "density",
  { data_type => "double precision", is_nullable => 1 },
  "decval",
  { data_type => "double precision", is_nullable => 1 },
  "frtins",
  { data_type => "double precision", is_nullable => 1 },
  "nmfc",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "class",
  { data_type => "double precision", is_nullable => 1 },
  "partnumber",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "originalcoid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "unitofmeasure",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "boxnum",
  { data_type => "integer", is_nullable => 1 },
  "productquantity",
  { data_type => "integer", is_nullable => 1 },
  "dryicewt",
  { data_type => "integer", is_nullable => 1 },
  "consolidationtype",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</shipmentpackageid>

=back

=cut

__PACKAGE__->set_primary_key("shipmentpackageid");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QzwqgLeHMQXRstq525+ojw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
