use utf8;
package IntelliShip::ArrsClass::Result::DhlIntlNonPostal;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::DhlIntlNonPostal

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

=head1 TABLE: C<dhlintlnonpostal>

=cut

__PACKAGE__->table("dhlintlnonpostal");

=head1 ACCESSORS

=head2 cityname

  data_type: 'varchar'
  is_nullable: 1
  size: 35

=head2 cityqualifier

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 countrycode

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 serviceareacode

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 servicestandard

  data_type: 'varchar'
  is_nullable: 1
  size: 2

=cut

__PACKAGE__->add_columns(
  "cityname",
  { data_type => "varchar", is_nullable => 1, size => 35 },
  "cityqualifier",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "countrycode",
  { data_type => "char", is_nullable => 1, size => 2 },
  "serviceareacode",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "servicestandard",
  { data_type => "varchar", is_nullable => 1, size => 2 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZcYk9TivQXt5qdKt22UXPg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
