use utf8;
package IntelliShip::ArrsClass::Result::Rate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::Rate

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

=head1 TABLE: C<rate>

=cut

__PACKAGE__->table("rate");

=head1 ACCESSORS

=head2 rateid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 typeid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 unitsstart

  data_type: 'integer'
  is_nullable: 1

=head2 unitsstop

  data_type: 'integer'
  is_nullable: 1

=head2 zonenumber

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 arcost

  data_type: 'real'
  is_nullable: 1

=head2 arcostmin

  data_type: 'real'
  is_nullable: 1

=head2 arcostperwt

  data_type: 'real'
  is_nullable: 1

=head2 arcostpermile

  data_type: 'real'
  is_nullable: 1

=head2 apcost

  data_type: 'real'
  is_nullable: 1

=head2 apcostmin

  data_type: 'real'
  is_nullable: 1

=head2 apcostperwt

  data_type: 'real'
  is_nullable: 1

=head2 apcostpermile

  data_type: 'real'
  is_nullable: 1

=head2 arcostperunit

  data_type: 'real'
  is_nullable: 1

=head2 apcostperunit

  data_type: 'real'
  is_nullable: 1

=head2 unittype

  data_type: 'integer'
  is_nullable: 1

=head2 startdate

  data_type: 'date'
  is_nullable: 1

=head2 stopdate

  data_type: 'date'
  is_nullable: 1

=head2 tier

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "rateid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "typeid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "unitsstart",
  { data_type => "integer", is_nullable => 1 },
  "unitsstop",
  { data_type => "integer", is_nullable => 1 },
  "zonenumber",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "arcost",
  { data_type => "real", is_nullable => 1 },
  "arcostmin",
  { data_type => "real", is_nullable => 1 },
  "arcostperwt",
  { data_type => "real", is_nullable => 1 },
  "arcostpermile",
  { data_type => "real", is_nullable => 1 },
  "apcost",
  { data_type => "real", is_nullable => 1 },
  "apcostmin",
  { data_type => "real", is_nullable => 1 },
  "apcostperwt",
  { data_type => "real", is_nullable => 1 },
  "apcostpermile",
  { data_type => "real", is_nullable => 1 },
  "arcostperunit",
  { data_type => "real", is_nullable => 1 },
  "apcostperunit",
  { data_type => "real", is_nullable => 1 },
  "unittype",
  { data_type => "integer", is_nullable => 1 },
  "startdate",
  { data_type => "date", is_nullable => 1 },
  "stopdate",
  { data_type => "date", is_nullable => 1 },
  "tier",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</rateid>

=back

=cut

__PACKAGE__->set_primary_key("rateid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UyfF0ExZoMKC0SKzVDtKJg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
