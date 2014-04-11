use utf8;
package IntelliShip::ArrsClass::Result::ClassData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::ClassData

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

=head1 TABLE: C<classdata>

=cut

__PACKAGE__->table("classdata");

=head1 ACCESSORS

=head2 classdataid

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

=head2 fak

  data_type: 'real'
  is_nullable: 1

=head2 classlow

  data_type: 'real'
  is_nullable: 1

=head2 classhigh

  data_type: 'real'
  is_nullable: 1

=head2 discountpercent

  data_type: 'real'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "classdataid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "ownertypeid",
  { data_type => "integer", is_nullable => 1 },
  "ownerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "fak",
  { data_type => "real", is_nullable => 1 },
  "classlow",
  { data_type => "real", is_nullable => 1 },
  "classhigh",
  { data_type => "real", is_nullable => 1 },
  "discountpercent",
  { data_type => "real", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</classdataid>

=back

=cut

__PACKAGE__->set_primary_key("classdataid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rjLxRcSK52mVZ0zA8ve4hg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
