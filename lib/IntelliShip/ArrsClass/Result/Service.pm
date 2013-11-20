use utf8;
package IntelliShip::ArrsClass::Result::Service;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::Service

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

=head1 TABLE: C<service>

=cut

__PACKAGE__->table("service");

=head1 ACCESSORS

=head2 serviceid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 carrierid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 servicename

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 webname

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 webhandlername

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 international

  data_type: 'integer'
  is_nullable: 1

=head2 heavy

  data_type: 'integer'
  is_nullable: 1

=head2 webname2

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 timeneededmin

  data_type: 'integer'
  is_nullable: 1

=head2 timeneededmax

  data_type: 'integer'
  is_nullable: 1

=head2 fscrate

  data_type: 'double precision'
  is_nullable: 1

=head2 dimfactor

  data_type: 'integer'
  is_nullable: 1

=head2 decvalinsrate

  data_type: 'double precision'
  is_nullable: 1

=head2 decvalinsmin

  data_type: 'integer'
  is_nullable: 1

=head2 decvalinsmax

  data_type: 'integer'
  is_nullable: 1

=head2 freightinsrate

  data_type: 'double precision'
  is_nullable: 1

=head2 decvalinsmincharge

  data_type: 'double precision'
  is_nullable: 1

=head2 freightinsincrement

  data_type: 'integer'
  is_nullable: 1

=head2 decvalinsmaxperlb

  data_type: 'double precision'
  is_nullable: 1

=head2 carrieremail

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 pickuprequest

  data_type: 'integer'
  is_nullable: 1

=head2 servicetypeid

  data_type: 'integer'
  is_nullable: 1

=head2 allowcod

  data_type: 'integer'
  is_nullable: 1

=head2 codfee

  data_type: 'double precision'
  is_nullable: 1

=head2 collectfreightcharge

  data_type: 'double precision'
  is_nullable: 1

=head2 guaranteeddelivery

  data_type: 'double precision'
  is_nullable: 1

=head2 saturdaysunday

  data_type: 'double precision'
  is_nullable: 1

=head2 liftgateservice

  data_type: 'double precision'
  is_nullable: 1

=head2 podservice

  data_type: 'double precision'
  is_nullable: 1

=head2 constructionsite

  data_type: 'double precision'
  is_nullable: 1

=head2 insidepickupdelivery

  data_type: 'double precision'
  is_nullable: 1

=head2 singleshipment

  data_type: 'double precision'
  is_nullable: 1

=head2 valuedependentrate

  data_type: 'integer'
  is_nullable: 1

=head2 thirdpartyacct

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 callforappointment

  data_type: 'double precision'
  is_nullable: 1

=head2 aggregateweightcost

  data_type: 'integer'
  is_nullable: 1

=head2 discountpercent

  data_type: 'double precision'
  is_nullable: 1

=head2 extservicecode

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 serviceicon

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 weekendupcharge

  data_type: 'double precision'
  is_nullable: 1

=head2 amc

  data_type: 'double precision'
  is_nullable: 1

=head2 cutofftime

  data_type: 'integer'
  is_nullable: 1

=head2 sattransit

  data_type: 'integer'
  is_nullable: 1

=head2 suntransit

  data_type: 'integer'
  is_nullable: 1

=head2 maxtruckweight

  data_type: 'integer'
  is_nullable: 1

=head2 alwaysshow

  data_type: 'integer'
  is_nullable: 1

=head2 modetypeid

  data_type: 'integer'
  is_nullable: 0

=head2 defaultzonetypeid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 servicecode

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 class

  data_type: 'real'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "serviceid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "carrierid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "servicename",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "webname",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "webhandlername",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "international",
  { data_type => "integer", is_nullable => 1 },
  "heavy",
  { data_type => "integer", is_nullable => 1 },
  "webname2",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "timeneededmin",
  { data_type => "integer", is_nullable => 1 },
  "timeneededmax",
  { data_type => "integer", is_nullable => 1 },
  "fscrate",
  { data_type => "double precision", is_nullable => 1 },
  "dimfactor",
  { data_type => "integer", is_nullable => 1 },
  "decvalinsrate",
  { data_type => "double precision", is_nullable => 1 },
  "decvalinsmin",
  { data_type => "integer", is_nullable => 1 },
  "decvalinsmax",
  { data_type => "integer", is_nullable => 1 },
  "freightinsrate",
  { data_type => "double precision", is_nullable => 1 },
  "decvalinsmincharge",
  { data_type => "double precision", is_nullable => 1 },
  "freightinsincrement",
  { data_type => "integer", is_nullable => 1 },
  "decvalinsmaxperlb",
  { data_type => "double precision", is_nullable => 1 },
  "carrieremail",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "pickuprequest",
  { data_type => "integer", is_nullable => 1 },
  "servicetypeid",
  { data_type => "integer", is_nullable => 1 },
  "allowcod",
  { data_type => "integer", is_nullable => 1 },
  "codfee",
  { data_type => "double precision", is_nullable => 1 },
  "collectfreightcharge",
  { data_type => "double precision", is_nullable => 1 },
  "guaranteeddelivery",
  { data_type => "double precision", is_nullable => 1 },
  "saturdaysunday",
  { data_type => "double precision", is_nullable => 1 },
  "liftgateservice",
  { data_type => "double precision", is_nullable => 1 },
  "podservice",
  { data_type => "double precision", is_nullable => 1 },
  "constructionsite",
  { data_type => "double precision", is_nullable => 1 },
  "insidepickupdelivery",
  { data_type => "double precision", is_nullable => 1 },
  "singleshipment",
  { data_type => "double precision", is_nullable => 1 },
  "valuedependentrate",
  { data_type => "integer", is_nullable => 1 },
  "thirdpartyacct",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "callforappointment",
  { data_type => "double precision", is_nullable => 1 },
  "aggregateweightcost",
  { data_type => "integer", is_nullable => 1 },
  "discountpercent",
  { data_type => "double precision", is_nullable => 1 },
  "extservicecode",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "serviceicon",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "weekendupcharge",
  { data_type => "double precision", is_nullable => 1 },
  "amc",
  { data_type => "double precision", is_nullable => 1 },
  "cutofftime",
  { data_type => "integer", is_nullable => 1 },
  "sattransit",
  { data_type => "integer", is_nullable => 1 },
  "suntransit",
  { data_type => "integer", is_nullable => 1 },
  "maxtruckweight",
  { data_type => "integer", is_nullable => 1 },
  "alwaysshow",
  { data_type => "integer", is_nullable => 1 },
  "modetypeid",
  { data_type => "integer", is_nullable => 0 },
  "defaultzonetypeid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "servicecode",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "class",
  { data_type => "real", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</serviceid>

=back

=cut

__PACKAGE__->set_primary_key("serviceid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7zTErxTGjfKPevkCUU8+3w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
