use utf8;
package IntelliShip::SchemaClass::Result::Postalcode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Postalcode

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

=head1 TABLE: C<postalcode>

=cut

__PACKAGE__->table("postalcode");

=head1 ACCESSORS

=head2 postalcode

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 province

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 city

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 lat

  data_type: 'double precision'
  is_nullable: 1

=head2 long

  data_type: 'double precision'
  is_nullable: 1

=head2 airportcode

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 baxairportcode

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 roadwayairportcode

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 roadwayextratransit

  data_type: 'integer'
  is_nullable: 1

=head2 rlairportcode

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 seflairportcode

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 watkinsairportcode

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 watkinsextratransit

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "postalcode",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "province",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "city",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "lat",
  { data_type => "double precision", is_nullable => 1 },
  "long",
  { data_type => "double precision", is_nullable => 1 },
  "airportcode",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "baxairportcode",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "roadwayairportcode",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "roadwayextratransit",
  { data_type => "integer", is_nullable => 1 },
  "rlairportcode",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "seflairportcode",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "watkinsairportcode",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "watkinsextratransit",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</postalcode>

=back

=cut

__PACKAGE__->set_primary_key("postalcode");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/x+Ov/zpKBobUQ0rsDol5g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
