use utf8;
package IntelliShip::ArrsClass::Result::AirPortCode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::AirPortCode

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

=head1 TABLE: C<airportcode>

=cut

__PACKAGE__->table("airportcode");

=head1 ACCESSORS

=head2 airportcodeid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 carrierid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 postalcode

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 airportcode

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 extratransit

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "airportcodeid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "carrierid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "postalcode",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "airportcode",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "extratransit",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</airportcodeid>

=back

=cut

__PACKAGE__->set_primary_key("airportcodeid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Cw1Bkly+1tKyEqFNqNCfTA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
