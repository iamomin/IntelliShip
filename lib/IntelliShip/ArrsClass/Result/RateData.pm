use utf8;
package IntelliShip::ArrsClass::Result::RateData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::RateData

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

=head1 TABLE: C<ratedata>

=cut

__PACKAGE__->table("ratedata");

=head1 ACCESSORS

=head2 ratedataid

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

=head2 band

  data_type: 'integer'
  is_nullable: 1

=head2 unitsstart

  data_type: 'real'
  is_nullable: 1

=head2 unitsstop

  data_type: 'real'
  is_nullable: 1

=head2 ardiscount

  data_type: 'real'
  is_nullable: 1

=head2 armin

  data_type: 'real'
  is_nullable: 1

=head2 apdiscount

  data_type: 'real'
  is_nullable: 1

=head2 apmin

  data_type: 'real'
  is_nullable: 1

=head2 customerid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 zone

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 startdate

  data_type: 'date'
  is_nullable: 1

=head2 stopdate

  data_type: 'date'
  is_nullable: 1

=head2 cwt

  data_type: 'integer'
  is_nullable: 1

=head2 intltype

  data_type: 'integer'
  is_nullable: 1

=head2 freightmarkupamt

  data_type: 'real'
  is_nullable: 1

=head2 freightmarkuppercent

  data_type: 'real'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ratedataid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "ownertypeid",
  { data_type => "integer", is_nullable => 1 },
  "ownerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "band",
  { data_type => "integer", is_nullable => 1 },
  "unitsstart",
  { data_type => "real", is_nullable => 1 },
  "unitsstop",
  { data_type => "real", is_nullable => 1 },
  "ardiscount",
  { data_type => "real", is_nullable => 1 },
  "armin",
  { data_type => "real", is_nullable => 1 },
  "apdiscount",
  { data_type => "real", is_nullable => 1 },
  "apmin",
  { data_type => "real", is_nullable => 1 },
  "customerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "zone",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "startdate",
  { data_type => "date", is_nullable => 1 },
  "stopdate",
  { data_type => "date", is_nullable => 1 },
  "cwt",
  { data_type => "integer", is_nullable => 1 },
  "intltype",
  { data_type => "integer", is_nullable => 1 },
  "freightmarkupamt",
  { data_type => "real", is_nullable => 1 },
  "freightmarkuppercent",
  { data_type => "real", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ratedataid>

=back

=cut

__PACKAGE__->set_primary_key("ratedataid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LmQbQ0TObYuY/k2aUqAorg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
