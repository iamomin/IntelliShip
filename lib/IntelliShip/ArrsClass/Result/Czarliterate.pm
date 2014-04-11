use utf8;
package IntelliShip::ArrsClass::Result::Czarliterate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::Czarliterate

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

=head1 TABLE: C<czarliterate>

=cut

__PACKAGE__->table("czarliterate");

=head1 ACCESSORS

=head2 rateid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 ratetypeid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 carrierscac

  data_type: 'char'
  is_nullable: 1
  size: 3

=head2 originbegin

  data_type: 'char'
  is_nullable: 1
  size: 5

=head2 originend

  data_type: 'char'
  is_nullable: 1
  size: 5

=head2 originstate

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 destbegin

  data_type: 'char'
  is_nullable: 1
  size: 5

=head2 destend

  data_type: 'char'
  is_nullable: 1
  size: 5

=head2 deststate

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 class

  data_type: 'integer'
  is_nullable: 1

=head2 mc1

  data_type: 'real'
  is_nullable: 1

=head2 mc2

  data_type: 'real'
  is_nullable: 1

=head2 mc3

  data_type: 'real'
  is_nullable: 1

=head2 mc4

  data_type: 'real'
  is_nullable: 1

=head2 l5c

  data_type: 'real'
  is_nullable: 1

=head2 m5c

  data_type: 'real'
  is_nullable: 1

=head2 m1m

  data_type: 'real'
  is_nullable: 1

=head2 m2m

  data_type: 'real'
  is_nullable: 1

=head2 m5m

  data_type: 'real'
  is_nullable: 1

=head2 m10m

  data_type: 'real'
  is_nullable: 1

=head2 m20m

  data_type: 'real'
  is_nullable: 1

=head2 m30m

  data_type: 'real'
  is_nullable: 1

=head2 m40m

  data_type: 'real'
  is_nullable: 1

=head2 rbno

  data_type: 'char'
  is_nullable: 1
  size: 6

=head2 mc5

  data_type: 'real'
  is_nullable: 1

=head2 mc6

  data_type: 'real'
  is_nullable: 1

=head2 mc7

  data_type: 'real'
  is_nullable: 1

=head2 mc8

  data_type: 'real'
  is_nullable: 1

=head2 ssmc1

  data_type: 'real'
  is_nullable: 1

=head2 ssmc2

  data_type: 'real'
  is_nullable: 1

=head2 ssmc3

  data_type: 'real'
  is_nullable: 1

=head2 ssmc4

  data_type: 'real'
  is_nullable: 1

=head2 ssmc5

  data_type: 'real'
  is_nullable: 1

=head2 ssmc6

  data_type: 'real'
  is_nullable: 1

=head2 ssmc7

  data_type: 'real'
  is_nullable: 1

=head2 ssmc8

  data_type: 'real'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "rateid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "ratetypeid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "carrierscac",
  { data_type => "char", is_nullable => 1, size => 3 },
  "originbegin",
  { data_type => "char", is_nullable => 1, size => 5 },
  "originend",
  { data_type => "char", is_nullable => 1, size => 5 },
  "originstate",
  { data_type => "char", is_nullable => 1, size => 2 },
  "destbegin",
  { data_type => "char", is_nullable => 1, size => 5 },
  "destend",
  { data_type => "char", is_nullable => 1, size => 5 },
  "deststate",
  { data_type => "char", is_nullable => 1, size => 2 },
  "class",
  { data_type => "integer", is_nullable => 1 },
  "mc1",
  { data_type => "real", is_nullable => 1 },
  "mc2",
  { data_type => "real", is_nullable => 1 },
  "mc3",
  { data_type => "real", is_nullable => 1 },
  "mc4",
  { data_type => "real", is_nullable => 1 },
  "l5c",
  { data_type => "real", is_nullable => 1 },
  "m5c",
  { data_type => "real", is_nullable => 1 },
  "m1m",
  { data_type => "real", is_nullable => 1 },
  "m2m",
  { data_type => "real", is_nullable => 1 },
  "m5m",
  { data_type => "real", is_nullable => 1 },
  "m10m",
  { data_type => "real", is_nullable => 1 },
  "m20m",
  { data_type => "real", is_nullable => 1 },
  "m30m",
  { data_type => "real", is_nullable => 1 },
  "m40m",
  { data_type => "real", is_nullable => 1 },
  "rbno",
  { data_type => "char", is_nullable => 1, size => 6 },
  "mc5",
  { data_type => "real", is_nullable => 1 },
  "mc6",
  { data_type => "real", is_nullable => 1 },
  "mc7",
  { data_type => "real", is_nullable => 1 },
  "mc8",
  { data_type => "real", is_nullable => 1 },
  "ssmc1",
  { data_type => "real", is_nullable => 1 },
  "ssmc2",
  { data_type => "real", is_nullable => 1 },
  "ssmc3",
  { data_type => "real", is_nullable => 1 },
  "ssmc4",
  { data_type => "real", is_nullable => 1 },
  "ssmc5",
  { data_type => "real", is_nullable => 1 },
  "ssmc6",
  { data_type => "real", is_nullable => 1 },
  "ssmc7",
  { data_type => "real", is_nullable => 1 },
  "ssmc8",
  { data_type => "real", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</rateid>

=back

=cut

__PACKAGE__->set_primary_key("rateid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A55xzAjNe4a90vVthCZQug


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
