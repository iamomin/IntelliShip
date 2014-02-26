use utf8;
package IntelliShip::SchemaClass::Result::Assdata;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Assdata

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

=head1 TABLE: C<assdata>

=cut

__PACKAGE__->table("assdata");

=head1 ACCESSORS

=head2 assdataid

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

=head2 assname

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 assdisplay

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 assvalue

  data_type: 'real'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "assdataid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "ownertypeid",
  { data_type => "integer", is_nullable => 1 },
  "ownerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "assname",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "assdisplay",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "assvalue",
  { data_type => "real", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nTSrE347mchCrofJiIr0NA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
