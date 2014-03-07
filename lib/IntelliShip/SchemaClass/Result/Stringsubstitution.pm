use utf8;
package IntelliShip::SchemaClass::Result::Stringsubstitution;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Stringsubstitution

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

=head1 TABLE: C<stringsubstitution>

=cut

__PACKAGE__->table("stringsubstitution");

=head1 ACCESSORS

=head2 string

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 substitution

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 level

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "string",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "substitution",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "level",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pIyu8nGWN/0tBR1n0wuaeg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
