use utf8;
package IntelliShip::SchemaClass::Result::Country;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Country

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

=head1 TABLE: C<country>

=cut

__PACKAGE__->table("country");

=head1 ACCESSORS

=head2 countryid

  data_type: 'char'
  is_nullable: 0
  size: 3

=head2 countryname

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 countryiso2

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 countryiso3

  data_type: 'char'
  is_nullable: 1
  size: 3

=head2 countryfips

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 countryinternet

  data_type: 'varchar'
  is_nullable: 1
  size: 5

=head2 currency

  data_type: 'char'
  is_nullable: 1
  size: 3

=cut

__PACKAGE__->add_columns(
  "countryid",
  { data_type => "char", is_nullable => 0, size => 3 },
  "countryname",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "countryiso2",
  { data_type => "char", is_nullable => 1, size => 2 },
  "countryiso3",
  { data_type => "char", is_nullable => 1, size => 3 },
  "countryfips",
  { data_type => "char", is_nullable => 1, size => 2 },
  "countryinternet",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "currency",
  { data_type => "char", is_nullable => 1, size => 3 },
);

=head1 PRIMARY KEY

=over 4

=item * L</countryid>

=back

=cut

__PACKAGE__->set_primary_key("countryid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:X5qQr5eHi3fa6j6zWWHIng


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
