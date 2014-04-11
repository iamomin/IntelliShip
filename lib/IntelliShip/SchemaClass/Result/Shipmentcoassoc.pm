use utf8;
package IntelliShip::SchemaClass::Result::Shipmentcoassoc;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Shipmentcoassoc

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

=head1 TABLE: C<shipmentcoassoc>

=cut

__PACKAGE__->table("shipmentcoassoc");

=head1 ACCESSORS

=head2 shipmentid

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 13

=head2 coid

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 13

=cut

__PACKAGE__->add_columns(
  "shipmentid",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 13 },
  "coid",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 13 },
);

=head1 PRIMARY KEY

=over 4

=item * L</shipmentid>

=item * L</coid>

=back

=cut

__PACKAGE__->set_primary_key("shipmentid", "coid");

=head1 RELATIONS

=head2 coid

Type: belongs_to

Related object: L<IntelliShip::SchemaClass::Result::Co>

=cut

__PACKAGE__->belongs_to(
  "coid",
  "IntelliShip::SchemaClass::Result::Co",
  { coid => "coid" },
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


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8221h5geHK66K8zgsS+j0Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
