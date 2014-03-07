use utf8;
package IntelliShip::SchemaClass::Result::Dhlshipmentinfo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Dhlshipmentinfo

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

=head1 TABLE: C<dhlshipmentinfo>

=cut

__PACKAGE__->table("dhlshipmentinfo");

=head1 ACCESSORS

=head2 shipmentid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 originsac

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 destinsac

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=cut

__PACKAGE__->add_columns(
  "shipmentid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "originsac",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "destinsac",
  { data_type => "varchar", is_nullable => 1, size => 3 },
);

=head1 PRIMARY KEY

=over 4

=item * L</shipmentid>

=back

=cut

__PACKAGE__->set_primary_key("shipmentid");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BEKopNrlDnknrG2jw2ua8w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
