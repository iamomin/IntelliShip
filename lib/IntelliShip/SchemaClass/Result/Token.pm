use utf8;
package IntelliShip::SchemaClass::Result::Token;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Token

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

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<token>

=cut

__PACKAGE__->table("token");

=head1 ACCESSORS

=head2 tokenid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 customerid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 datecreated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 dateexpires

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 active_username

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 brandingid

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=head2 ssoid

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=cut

__PACKAGE__->add_columns(
  "tokenid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "customerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "datecreated",
  { data_type => "timestamp with time zone", is_nullable => 1, set_on_create => 1 },
  "dateexpires",
  { data_type => "timestamp with time zone", is_nullable => 1, set_on_create => 1 },
  "active_username",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "brandingid",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "ssoid",
  { data_type => "varchar", is_nullable => 1, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</tokenid>

=back

=cut

__PACKAGE__->set_primary_key("tokenid");

# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HIjVjhRdv3gBoykhxO314g
 
__PACKAGE__->belongs_to( 'customer', 'IntelliShip::SchemaClass::Result::Customer', 'customerid' );

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
