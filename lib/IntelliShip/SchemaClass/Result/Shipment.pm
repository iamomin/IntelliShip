use utf8;
package IntelliShip::SchemaClass::Result::Shipment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Shipment

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

=head1 TABLE: C<shipment>

=cut

__PACKAGE__->table("shipment");

=head1 ACCESSORS

=head2 shipmentid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 customerserviceid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 coid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 statusid

  data_type: 'integer'
  is_nullable: 1

=head2 tracking1

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 weight

  data_type: 'double precision'
  is_nullable: 1

=head2 quantity

  data_type: 'integer'
  is_nullable: 1

=head2 cost

  data_type: 'double precision'
  is_nullable: 1

=head2 insurance

  data_type: 'double precision'
  is_nullable: 1

=head2 podname

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 dateshipped

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 datecreated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 datedelivered

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 500

=head2 labelfilename

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 otherid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 subworkorderid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 dimlength

  data_type: 'double precision'
  is_nullable: 1

=head2 dimwidth

  data_type: 'double precision'
  is_nullable: 1

=head2 dimheight

  data_type: 'double precision'
  is_nullable: 1

=head2 currencytype

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 destinationcountry

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 manufacturecountry

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 dutypaytype

  data_type: 'integer'
  is_nullable: 1

=head2 dutyaccount

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 termsofsale

  data_type: 'integer'
  is_nullable: 1

=head2 commodityunits

  data_type: 'varchar'
  is_nullable: 1
  size: 5

=head2 commodityquantity

  data_type: 'double precision'
  is_nullable: 1

=head2 commodityweight

  data_type: 'double precision'
  is_nullable: 1

=head2 commodityunitvalue

  data_type: 'double precision'
  is_nullable: 1

=head2 commoditycustomsvalue

  data_type: 'double precision'
  is_nullable: 1

=head2 unitquantity

  data_type: 'double precision'
  is_nullable: 1

=head2 customsvalue

  data_type: 'double precision'
  is_nullable: 1

=head2 partiestotransaction

  data_type: 'varchar'
  is_nullable: 1
  size: 1

=head2 customsdescription

  data_type: 'varchar'
  is_nullable: 1
  size: 150

=head2 harmonizedcode

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 ssnein

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 naftaflag

  data_type: 'varchar'
  is_nullable: 1
  size: 1

=head2 dimunits

  data_type: 'varchar'
  is_nullable: 1
  size: 2

=head2 billingaccount

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 contactname

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 contactphone

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 shipqty

  data_type: 'integer'
  is_nullable: 1

=head2 shiptypeid

  data_type: 'integer'
  is_nullable: 1

=head2 defaultcsid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 carrier

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 service

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 halovoiddate

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 freightinsurance

  data_type: 'double precision'
  is_nullable: 1

=head2 dimweight

  data_type: 'double precision'
  is_nullable: 1

=head2 density

  data_type: 'double precision'
  is_nullable: 1

=head2 ipaddress

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 custnum

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 billingpostalcode

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 pickuprequest

  data_type: 'integer'
  is_nullable: 1

=head2 shipasname

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 zonenumber

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 hazardous

  data_type: 'integer'
  is_nullable: 1

=head2 datetodeliver

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 dateneededon

  data_type: 'integer'
  is_nullable: 1

=head2 manualthirdparty

  data_type: 'integer'
  is_nullable: 1

=head2 datedue

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 originid

  data_type: 'integer'
  is_nullable: 1

=head2 ponumber

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 securitytype

  data_type: 'integer'
  is_nullable: 1

=head2 shipmentnotification

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 deliverynotification

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 contactid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 addressidorigin

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 addressiddestin

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 ssccnumber

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 thirdpartybilling

  data_type: 'integer'
  is_nullable: 1

=head2 chargediffthresholdamt

  data_type: 'double precision'
  is_nullable: 1

=head2 extid

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 custref2

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 custref3

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 freightcharges

  data_type: 'integer'
  is_nullable: 1

=head2 department

  data_type: 'varchar'
  is_nullable: 1
  size: 500

=head2 oacontactname

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 oacontactphone

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 datereceived

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 daterouted

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 datepacked

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 isinbound

  data_type: 'integer'
  is_nullable: 1

=head2 mode

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 isdropship

  data_type: 'integer'
  is_nullable: 1

=head2 quantityxweight

  data_type: 'integer'
  is_nullable: 1

=head2 exportfile

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 clientdatecreated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 bookingnumber

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 volume

  data_type: 'real'
  is_nullable: 1

=head2 batch

  data_type: 'varchar'
  is_nullable: 1
  size: 13

=head2 contacttitle

  data_type: 'varchar'
  is_nullable: 1
  size: 35

=cut

__PACKAGE__->add_columns(
  "shipmentid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "customerserviceid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "coid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "statusid",
  { data_type => "integer", is_nullable => 1 },
  "tracking1",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "weight",
  { data_type => "double precision", is_nullable => 1 },
  "quantity",
  { data_type => "integer", is_nullable => 1 },
  "cost",
  { data_type => "double precision", is_nullable => 1 },
  "insurance",
  { data_type => "double precision", is_nullable => 1 },
  "podname",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "dateshipped",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "datecreated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "datedelivered",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 500 },
  "labelfilename",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "otherid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "subworkorderid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "dimlength",
  { data_type => "double precision", is_nullable => 1 },
  "dimwidth",
  { data_type => "double precision", is_nullable => 1 },
  "dimheight",
  { data_type => "double precision", is_nullable => 1 },
  "currencytype",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "destinationcountry",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "manufacturecountry",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "dutypaytype",
  { data_type => "integer", is_nullable => 1 },
  "dutyaccount",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "termsofsale",
  { data_type => "integer", is_nullable => 1 },
  "commodityunits",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "commodityquantity",
  { data_type => "double precision", is_nullable => 1 },
  "commodityweight",
  { data_type => "double precision", is_nullable => 1 },
  "commodityunitvalue",
  { data_type => "double precision", is_nullable => 1 },
  "commoditycustomsvalue",
  { data_type => "double precision", is_nullable => 1 },
  "unitquantity",
  { data_type => "double precision", is_nullable => 1 },
  "customsvalue",
  { data_type => "double precision", is_nullable => 1 },
  "partiestotransaction",
  { data_type => "varchar", is_nullable => 1, size => 1 },
  "customsdescription",
  { data_type => "varchar", is_nullable => 1, size => 150 },
  "harmonizedcode",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "ssnein",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "naftaflag",
  { data_type => "varchar", is_nullable => 1, size => 1 },
  "dimunits",
  { data_type => "varchar", is_nullable => 1, size => 2 },
  "billingaccount",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "contactname",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "contactphone",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "shipqty",
  { data_type => "integer", is_nullable => 1 },
  "shiptypeid",
  { data_type => "integer", is_nullable => 1 },
  "defaultcsid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "carrier",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "service",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "halovoiddate",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "freightinsurance",
  { data_type => "double precision", is_nullable => 1 },
  "dimweight",
  { data_type => "double precision", is_nullable => 1 },
  "density",
  { data_type => "double precision", is_nullable => 1 },
  "ipaddress",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "custnum",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "billingpostalcode",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "pickuprequest",
  { data_type => "integer", is_nullable => 1 },
  "shipasname",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "zonenumber",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "hazardous",
  { data_type => "integer", is_nullable => 1 },
  "datetodeliver",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "dateneededon",
  { data_type => "integer", is_nullable => 1 },
  "manualthirdparty",
  { data_type => "integer", is_nullable => 1 },
  "datedue",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "originid",
  { data_type => "integer", is_nullable => 1 },
  "ponumber",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "securitytype",
  { data_type => "integer", is_nullable => 1 },
  "shipmentnotification",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "deliverynotification",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "contactid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "addressidorigin",
  { data_type => "char", is_nullable => 1, size => 13 },
  "addressiddestin",
  { data_type => "char", is_nullable => 1, size => 13 },
  "ssccnumber",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "thirdpartybilling",
  { data_type => "integer", is_nullable => 1 },
  "chargediffthresholdamt",
  { data_type => "double precision", is_nullable => 1 },
  "extid",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "custref2",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "custref3",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "freightcharges",
  { data_type => "integer", is_nullable => 1 },
  "department",
  { data_type => "varchar", is_nullable => 1, size => 500 },
  "oacontactname",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "oacontactphone",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "datereceived",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "daterouted",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "datepacked",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "isinbound",
  { data_type => "integer", is_nullable => 1 },
  "mode",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "isdropship",
  { data_type => "integer", is_nullable => 1 },
  "quantityxweight",
  { data_type => "integer", is_nullable => 1 },
  "exportfile",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "clientdatecreated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "bookingnumber",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "volume",
  { data_type => "real", is_nullable => 1 },
  "batch",
  { data_type => "varchar", is_nullable => 1, size => 13 },
  "contacttitle",
  { data_type => "varchar", is_nullable => 1, size => 35 },
);

=head1 PRIMARY KEY

=over 4

=item * L</shipmentid>

=back

=cut

__PACKAGE__->set_primary_key("shipmentid");

=head1 RELATIONS

=head2 manifestshipments

Type: has_many

Related object: L<IntelliShip::SchemaClass::Result::Manifestshipment>

=cut

__PACKAGE__->has_many(
  "manifestshipments",
  "IntelliShip::SchemaClass::Result::Manifestshipment",
  { "foreign.shipmentid" => "self.shipmentid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 shipmentcoassocs

Type: has_many

Related object: L<IntelliShip::SchemaClass::Result::Shipmentcoassoc>

=cut

__PACKAGE__->has_many(
  "shipmentcoassocs",
  "IntelliShip::SchemaClass::Result::Shipmentcoassoc",
  { "foreign.shipmentid" => "self.shipmentid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 shipmentproducts

Type: has_many

Related object: L<IntelliShip::SchemaClass::Result::Shipmentproduct>

=cut

__PACKAGE__->has_many(
  "shipmentproducts",
  "IntelliShip::SchemaClass::Result::Shipmentproduct",
  { "foreign.shipmentid" => "self.shipmentid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 coids

Type: many_to_many

Composing rels: L</shipmentcoassocs> -> coid

=cut

__PACKAGE__->many_to_many("coids", "shipmentcoassocs", "coid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SIqsoxucVnH7m+CvW/xJxg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
