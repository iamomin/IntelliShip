use utf8;
package IntelliShip::ArrsClass::Result::BandData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::BandData

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

=head1 TABLE: C<banddata>

=cut

__PACKAGE__->table("banddata");

=head1 ACCESSORS

=head2 banddataid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 ownertypeid

  data_type: 'integer'
  is_nullable: 1

=head2 ownerid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 bandtype

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 dollarstart

  data_type: 'real'
  is_nullable: 1

=head2 dollarstop

  data_type: 'real'
  is_nullable: 1

=head2 band

  data_type: 'integer'
  is_nullable: 1

=head2 startdate

  data_type: 'date'
  is_nullable: 1

=head2 stopdate

  data_type: 'date'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "banddataid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "ownertypeid",
  { data_type => "integer", is_nullable => 1 },
  "ownerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "bandtype",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "dollarstart",
  { data_type => "real", is_nullable => 1 },
  "dollarstop",
  { data_type => "real", is_nullable => 1 },
  "band",
  { data_type => "integer", is_nullable => 1 },
  "startdate",
  { data_type => "date", is_nullable => 1 },
  "stopdate",
  { data_type => "date", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</banddataid>

=back

=cut

__PACKAGE__->set_primary_key("banddataid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:li8dgNAKUTLHwQIzL7n7qw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
