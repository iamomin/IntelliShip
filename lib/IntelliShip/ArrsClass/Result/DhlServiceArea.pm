use utf8;
package IntelliShip::ArrsClass::Result::DhlServiceArea;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::DhlServiceArea

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

=head1 TABLE: C<dhlservicearea>

=cut

__PACKAGE__->table("dhlservicearea");

=head1 ACCESSORS

=head2 serviceareacode

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 productcode

  data_type: 'varchar'
  is_nullable: 1
  size: 35

=head2 countrycode

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 countryname

  data_type: 'varchar'
  is_nullable: 1
  size: 35

=head2 cityname

  data_type: 'varchar'
  is_nullable: 1
  size: 35

=cut

__PACKAGE__->add_columns(
  "serviceareacode",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "productcode",
  { data_type => "varchar", is_nullable => 1, size => 35 },
  "countrycode",
  { data_type => "char", is_nullable => 1, size => 2 },
  "countryname",
  { data_type => "varchar", is_nullable => 1, size => 35 },
  "cityname",
  { data_type => "varchar", is_nullable => 1, size => 35 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LyKuanvXkWLo10hPOPH2tA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
