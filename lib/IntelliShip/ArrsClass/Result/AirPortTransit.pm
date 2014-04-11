use utf8;
package IntelliShip::ArrsClass::Result::AirPortTransit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::AirPortTransit

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

=head1 TABLE: C<airporttransit>

=cut

__PACKAGE__->table("airporttransit");

=head1 ACCESSORS

=head2 airporttransitid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 carrierid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 origincode

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 destcode

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 transittime

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "airporttransitid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "carrierid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "origincode",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "destcode",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "transittime",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</airporttransitid>

=back

=cut

__PACKAGE__->set_primary_key("airporttransitid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ng64g8ci7BAGbJZgVkzPwQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
