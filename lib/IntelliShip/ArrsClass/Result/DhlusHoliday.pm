use utf8;
package IntelliShip::ArrsClass::Result::DhlusHoliday;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::DhlusHoliday

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

=head1 TABLE: C<dhlusholidays>

=cut

__PACKAGE__->table("dhlusholidays");

=head1 ACCESSORS

=head2 countrycode

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 holidaydate

  data_type: 'date'
  is_nullable: 1

=head2 hoidayname

  data_type: 'varchar'
  is_nullable: 1
  size: 35

=head2 holidaytype

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=head2 serviceareacode

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 comment

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=cut

__PACKAGE__->add_columns(
  "countrycode",
  { data_type => "char", is_nullable => 1, size => 2 },
  "holidaydate",
  { data_type => "date", is_nullable => 1 },
  "hoidayname",
  { data_type => "varchar", is_nullable => 1, size => 35 },
  "holidaytype",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "serviceareacode",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "comment",
  { data_type => "varchar", is_nullable => 1, size => 50 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eBwTPxPa/im7Tape/bxUXA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
