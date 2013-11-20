use utf8;
package IntelliShip::ArrsClass::Result::Zone;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::Zone

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

=head1 TABLE: C<zone>

=cut

__PACKAGE__->table("zone");

=head1 ACCESSORS

=head2 zoneid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 typeid

  data_type: 'char'
  is_nullable: 1
  size: 13

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

=head2 zonenumber

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 transittime

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "zoneid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "typeid",
  { data_type => "char", is_nullable => 1, size => 13 },
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
  "zonenumber",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "transittime",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</zoneid>

=back

=cut

__PACKAGE__->set_primary_key("zoneid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5Tv2rzsQS/a3jOuXQb9xWQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
