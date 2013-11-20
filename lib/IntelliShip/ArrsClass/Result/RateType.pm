use utf8;
package IntelliShip::ArrsClass::Result::RateType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::RateType

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

=head1 TABLE: C<ratetype>

=cut

__PACKAGE__->table("ratetype");

=head1 ACCESSORS

=head2 typeid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 serviceid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 ratetypename

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 handler

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 lookuptype

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "typeid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "serviceid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "ratetypename",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "handler",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "lookuptype",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</typeid>

=back

=cut

__PACKAGE__->set_primary_key("typeid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QmyPwjDl0gd51O8i9Cm6tQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
