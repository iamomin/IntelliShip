use utf8;
package IntelliShip::ArrsClass::Result::Georate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::Georate

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

=head1 TABLE: C<georate>

=cut

__PACKAGE__->table("georate");

=head1 ACCESSORS

=head2 georateid

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

=head2 georatetypeid

  data_type: 'integer'
  is_nullable: 1

=head2 originbegin

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 originend

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 destbegin

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 destend

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 originstate

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 deststate

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 origincountry

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 destcountry

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 arcost

  data_type: 'real'
  is_nullable: 1

=head2 apcost

  data_type: 'real'
  is_nullable: 1

=head2 ardiscountpercent

  data_type: 'real'
  is_nullable: 1

=head2 apdiscountpercent

  data_type: 'real'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "georateid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "ownertypeid",
  { data_type => "integer", is_nullable => 1 },
  "ownerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "georatetypeid",
  { data_type => "integer", is_nullable => 1 },
  "originbegin",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "originend",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "destbegin",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "destend",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "originstate",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "deststate",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "origincountry",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "destcountry",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "arcost",
  { data_type => "real", is_nullable => 1 },
  "apcost",
  { data_type => "real", is_nullable => 1 },
  "ardiscountpercent",
  { data_type => "real", is_nullable => 1 },
  "apdiscountpercent",
  { data_type => "real", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</georateid>

=back

=cut

__PACKAGE__->set_primary_key("georateid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GjD91UC/RuBo8Kw5gbCATQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
