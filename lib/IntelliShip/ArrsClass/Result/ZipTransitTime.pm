use utf8;
package IntelliShip::ArrsClass::Result::ZipTransitTime;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::ZipTransitTime

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

=head1 TABLE: C<ziptransittime>

=cut

__PACKAGE__->table("ziptransittime");

=head1 ACCESSORS

=head2 carrierid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 serviceid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 originbegin

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 originend

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 destbegin

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 destend

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 transittime

  data_type: 'integer'
  is_nullable: 1

=head2 routecode

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 dateeffective

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 dateexpires

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 datemodified

  data_type: 'timestamp with time zone'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "carrierid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "serviceid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "originbegin",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "originend",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "destbegin",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "destend",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "transittime",
  { data_type => "integer", is_nullable => 1 },
  "routecode",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "dateeffective",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "dateexpires",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "datemodified",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:67o6CD7cFtETlo8XogRToQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
