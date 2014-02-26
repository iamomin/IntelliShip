use utf8;
package IntelliShip::SchemaClass::Result::Routingzone;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Routingzone

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

=head1 TABLE: C<routingzone>

=cut

__PACKAGE__->table("routingzone");

=head1 ACCESSORS

=head2 zoneid

  data_type: 'char'
  is_nullable: 0
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

=head2 zonenumber

  data_type: 'varchar'
  is_nullable: 1
  size: 5

=cut

__PACKAGE__->add_columns(
  "zoneid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "originbegin",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "originend",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "destbegin",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "destend",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "zonenumber",
  { data_type => "varchar", is_nullable => 1, size => 5 },
);

=head1 PRIMARY KEY

=over 4

=item * L</zoneid>

=back

=cut

__PACKAGE__->set_primary_key("zoneid");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+rFbeGfXssoHc/Xe4t+9fg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
