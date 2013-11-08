use utf8;
package IntelliShip::SchemaClass::Result::Packprodata;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Packprodata

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

=head1 TABLE: C<packprodata>

=cut

__PACKAGE__->table("packprodata");

=head1 ACCESSORS

=head2 packprodataid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 ownertypeid

  data_type: 'integer'
  is_nullable: 1

=head2 ownerid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 datatypeid

  data_type: 'integer'
  is_nullable: 1

=head2 datecreated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 producttype

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 serialnumber

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 quantity

  data_type: 'integer'
  is_nullable: 1

=head2 partnumber

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 unittypeid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 weight

  data_type: 'double precision'
  is_nullable: 1

=head2 dimweight

  data_type: 'double precision'
  is_nullable: 1

=head2 weighttypeid

  data_type: 'integer'
  is_foreign_key: 1
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

=head2 hazardous

  data_type: 'integer'
  is_nullable: 1

=head2 originalcoid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 consolidationtype

  data_type: 'integer'
  is_nullable: 1

=head2 unitofmeasure

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 boxnum

  data_type: 'integer'
  is_nullable: 1

=head2 dryicewt

  data_type: 'integer'
  is_nullable: 1

=head2 linenum

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=head2 reqqty

  data_type: 'integer'
  is_nullable: 1

=head2 authnumber

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 authorized

  data_type: 'integer'
  is_nullable: 1

=head2 poppdid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 shippedqty

  data_type: 'integer'
  is_nullable: 1

=head2 poreason

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 statusid

  data_type: 'integer'
  is_nullable: 1

=head2 dgunnum

  data_type: 'varchar'
  is_nullable: 1
  size: 4

=head2 dgpkgtype

  data_type: 'varchar'
  is_nullable: 1
  size: 35

=head2 dgpkginstructions

  data_type: 'varchar'
  is_nullable: 1
  size: 4

=head2 dgpackinggroup

  data_type: 'varchar'
  is_nullable: 1
  size: 4

=cut

__PACKAGE__->add_columns(
  "packprodataid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "ownertypeid",
  { data_type => "integer", is_nullable => 1 },
  "ownerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "datatypeid",
  { data_type => "integer", is_nullable => 1 },
  "datecreated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "producttype",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "serialnumber",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "quantity",
  { data_type => "integer", is_nullable => 1 },
  "partnumber",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "unittypeid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "weight",
  { data_type => "double precision", is_nullable => 1 },
  "dimweight",
  { data_type => "double precision", is_nullable => 1 },
  "weighttypeid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "dimlength",
  { data_type => "double precision", is_nullable => 1 },
  "dimwidth",
  { data_type => "double precision", is_nullable => 1 },
  "dimheight",
  { data_type => "double precision", is_nullable => 1 },
  "density",
  { data_type => "double precision", is_nullable => 1 },
  "nmfc",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "class",
  { data_type => "double precision", is_nullable => 1 },
  "decval",
  { data_type => "double precision", is_nullable => 1 },
  "frtins",
  { data_type => "double precision", is_nullable => 1 },
  "hazardous",
  { data_type => "integer", is_nullable => 1 },
  "originalcoid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "consolidationtype",
  { data_type => "integer", is_nullable => 1 },
  "unitofmeasure",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "boxnum",
  { data_type => "integer", is_nullable => 1 },
  "dryicewt",
  { data_type => "integer", is_nullable => 1 },
  "linenum",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "reqqty",
  { data_type => "integer", is_nullable => 1 },
  "authnumber",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "authorized",
  { data_type => "integer", is_nullable => 1 },
  "poppdid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "shippedqty",
  { data_type => "integer", is_nullable => 1 },
  "poreason",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "statusid",
  { data_type => "integer", is_nullable => 1 },
  "dgunnum",
  { data_type => "varchar", is_nullable => 1, size => 4 },
  "dgpkgtype",
  { data_type => "varchar", is_nullable => 1, size => 35 },
  "dgpkginstructions",
  { data_type => "varchar", is_nullable => 1, size => 4 },
  "dgpackinggroup",
  { data_type => "varchar", is_nullable => 1, size => 4 },
);

=head1 PRIMARY KEY

=over 4

=item * L</packprodataid>

=back

=cut

__PACKAGE__->set_primary_key("packprodataid");

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lD6eS3kpg8AlJhdVZBffcg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
