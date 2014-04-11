use utf8;
package IntelliShip::ArrsClass::Result::Token;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::Token

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

=head1 TABLE: C<token>

=cut

__PACKAGE__->table("token");

=head1 ACCESSORS

=head2 tokenid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 contactid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 datecreated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 dateexpires

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 ipaddress

  data_type: 'varchar'
  is_nullable: 1
  size: 15

=cut

__PACKAGE__->add_columns(
  "tokenid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "contactid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "datecreated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "dateexpires",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "ipaddress",
  { data_type => "varchar", is_nullable => 1, size => 15 },
);

=head1 PRIMARY KEY

=over 4

=item * L</tokenid>

=back

=cut

__PACKAGE__->set_primary_key("tokenid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Q5Dntl0pCBTvvTdyX+k9Vg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
