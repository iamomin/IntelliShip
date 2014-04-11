use utf8;
package IntelliShip::ArrsClass::Result::DhlGroundTransit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::DhlGroundTransit

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

=head1 TABLE: C<dhlgroundtransit>

=cut

__PACKAGE__->table("dhlgroundtransit");

=head1 ACCESSORS

=head2 countrycode

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 originservicecode

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 destinservicecode

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 transitdays

  data_type: 'integer'
  is_nullable: 1

=head2 linehaulhub

  data_type: 'varchar'
  is_nullable: 1
  size: 4

=head2 linehaulterminal

  data_type: 'varchar'
  is_nullable: 1
  size: 4

=cut

__PACKAGE__->add_columns(
  "countrycode",
  { data_type => "char", is_nullable => 1, size => 2 },
  "originservicecode",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "destinservicecode",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "transitdays",
  { data_type => "integer", is_nullable => 1 },
  "linehaulhub",
  { data_type => "varchar", is_nullable => 1, size => 4 },
  "linehaulterminal",
  { data_type => "varchar", is_nullable => 1, size => 4 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VgyYJaAfwtIq18Y8QCvwgQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
