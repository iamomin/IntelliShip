use utf8;
package IntelliShip::SchemaClass::Result::Productstatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Productstatus

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

=head1 TABLE: C<productstatus>

=cut

__PACKAGE__->table("productstatus");

=head1 ACCESSORS

=head2 productstatusid

  data_type: 'integer'
  is_nullable: 0

=head2 productstatus

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "productstatusid",
  { data_type => "integer", is_nullable => 0 },
  "productstatus",
  { data_type => "varchar", is_nullable => 0, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</productstatusid>

=back

=cut

__PACKAGE__->set_primary_key("productstatusid");

=head1 RELATIONS

=head2 products

Type: has_many

Related object: L<IntelliShip::SchemaClass::Result::Product>

=cut

__PACKAGE__->has_many(
  "products",
  "IntelliShip::SchemaClass::Result::Product",
  { "foreign.statusid" => "self.productstatusid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zAHO5WPV8L3wgUXcq3RhBg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
