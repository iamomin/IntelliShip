use utf8;
package IntelliShip::SchemaClass::Result::Note;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Note

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

=head1 TABLE: C<notes>

=cut

__PACKAGE__->table("notes");

=head1 ACCESSORS

=head2 notesid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 ownerid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 notestypeid

  data_type: 'integer'
  is_nullable: 0

=head2 note

  data_type: 'varchar'
  is_nullable: 0
  size: 4000

=head2 contactid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 datecreated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 datehappened

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 clientdatecreated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "notesid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "ownerid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "notestypeid",
  { data_type => "integer", is_nullable => 0 },
  "note",
  { data_type => "varchar", is_nullable => 0, size => 4000 },
  "contactid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "datecreated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "datehappened",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "clientdatecreated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</notesid>

=back

=cut

__PACKAGE__->set_primary_key("notesid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:frD/rWDI3obODZptc3br5w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
