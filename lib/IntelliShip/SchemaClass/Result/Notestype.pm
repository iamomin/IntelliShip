use utf8;
package IntelliShip::SchemaClass::Result::Notestype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Notestype

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

=head1 TABLE: C<notestype>

=cut

__PACKAGE__->table("notestype");

=head1 ACCESSORS

=head2 notestypeid

  data_type: 'integer'
  is_nullable: 0

=head2 notestypename

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 visible

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "notestypeid",
  { data_type => "integer", is_nullable => 0 },
  "notestypename",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "visible",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</notestypeid>

=back

=cut

__PACKAGE__->set_primary_key("notestypeid");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RgXQiUTPoxV8qxqpEcp+LQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
