use utf8;
package IntelliShip::SchemaClass::Result::Loginlevel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Loginlevel

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

=head1 TABLE: C<loginlevel>

=cut

__PACKAGE__->table("loginlevel");

=head1 ACCESSORS

=head2 loginlevelid

  data_type: 'integer'
  is_nullable: 0

=head2 loginlevelname

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=cut

__PACKAGE__->add_columns(
  "loginlevelid",
  { data_type => "integer", is_nullable => 0 },
  "loginlevelname",
  { data_type => "varchar", is_nullable => 1, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</loginlevelid>

=back

=cut

__PACKAGE__->set_primary_key("loginlevelid");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+WXJiAZ7i6O1JBRtyWW5Rw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
