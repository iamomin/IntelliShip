use utf8;
package IntelliShip::SchemaClass::Result::Weighttype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Weighttype

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

=head1 TABLE: C<weighttype>

=cut

__PACKAGE__->table("weighttype");

=head1 ACCESSORS

=head2 weighttypeid

  data_type: 'integer'
  is_nullable: 0

=head2 weighttypename

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=cut

__PACKAGE__->add_columns(
  "weighttypeid",
  { data_type => "integer", is_nullable => 0 },
  "weighttypename",
  { data_type => "varchar", is_nullable => 1, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</weighttypeid>

=back

=cut

__PACKAGE__->set_primary_key("weighttypeid");

=head1 RELATIONS

=head2 packprodatas

Type: has_many

Related object: L<IntelliShip::SchemaClass::Result::Packprodata>

=cut

__PACKAGE__->has_many(
  "packprodatas",
  "IntelliShip::SchemaClass::Result::Packprodata",
  { "foreign.weighttypeid" => "self.weighttypeid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 products

Type: has_many

Related object: L<IntelliShip::SchemaClass::Result::Product>

=cut

__PACKAGE__->has_many(
  "products",
  "IntelliShip::SchemaClass::Result::Product",
  { "foreign.weighttypeid" => "self.weighttypeid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JKQ7gGMTD4yftFZNoIMo+g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
