use utf8;
package IntelliShip::SchemaClass::Result::Pothreshold;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Pothreshold

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

=head1 TABLE: C<pothreshold>

=cut

__PACKAGE__->table("pothreshold");

=head1 ACCESSORS

=head2 pothresholdid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 qtystart

  data_type: 'integer'
  is_nullable: 1

=head2 qtystop

  data_type: 'integer'
  is_nullable: 1

=head2 mintoship

  data_type: 'real'
  is_nullable: 1

=head2 maxtoship

  data_type: 'real'
  is_nullable: 1

=head2 vendorid

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 skuid

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=cut

__PACKAGE__->add_columns(
  "pothresholdid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "qtystart",
  { data_type => "integer", is_nullable => 1 },
  "qtystop",
  { data_type => "integer", is_nullable => 1 },
  "mintoship",
  { data_type => "real", is_nullable => 1 },
  "maxtoship",
  { data_type => "real", is_nullable => 1 },
  "vendorid",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "skuid",
  { data_type => "varchar", is_nullable => 1, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pothresholdid>

=back

=cut

__PACKAGE__->set_primary_key("pothresholdid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9tGfRoP6HhIO0UR5QSo41Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
