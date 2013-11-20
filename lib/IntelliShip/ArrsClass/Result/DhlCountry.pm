use utf8;
package IntelliShip::ArrsClass::Result::DhlCountry;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::DhlCountry

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

=head1 TABLE: C<dhlcountry>

=cut

__PACKAGE__->table("dhlcountry");

=head1 ACCESSORS

=head2 countrycode

  data_type: 'char'
  is_nullable: 0
  size: 2

=head2 countryname

  data_type: 'varchar'
  is_nullable: 1
  size: 35

=head2 currencycode

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 termsoftrade

  data_type: 'varchar'
  is_nullable: 1
  size: 5

=head2 invoicenumer

  data_type: 'varchar'
  is_nullable: 1
  size: 5

=head2 format

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 numericlength

  data_type: 'integer'
  is_nullable: 1

=head2 ddpin

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 ddpout

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 ddu

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 dvu

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 nds

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 exceptioncities

  data_type: 'char'
  is_nullable: 1
  size: 1

=cut

__PACKAGE__->add_columns(
  "countrycode",
  { data_type => "char", is_nullable => 0, size => 2 },
  "countryname",
  { data_type => "varchar", is_nullable => 1, size => 35 },
  "currencycode",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "termsoftrade",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "invoicenumer",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "format",
  { data_type => "char", is_nullable => 1, size => 1 },
  "numericlength",
  { data_type => "integer", is_nullable => 1 },
  "ddpin",
  { data_type => "char", is_nullable => 1, size => 1 },
  "ddpout",
  { data_type => "char", is_nullable => 1, size => 1 },
  "ddu",
  { data_type => "char", is_nullable => 1, size => 1 },
  "dvu",
  { data_type => "char", is_nullable => 1, size => 1 },
  "nds",
  { data_type => "char", is_nullable => 1, size => 1 },
  "exceptioncities",
  { data_type => "char", is_nullable => 1, size => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</countrycode>

=back

=cut

__PACKAGE__->set_primary_key("countrycode");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JSgsMmV26f8qnvwKz6OY8w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
