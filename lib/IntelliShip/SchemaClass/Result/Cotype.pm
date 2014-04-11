use utf8;
package IntelliShip::SchemaClass::Result::Cotype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Cotype

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

=head1 TABLE: C<cotype>

=cut

__PACKAGE__->table("cotype");

=head1 ACCESSORS

=head2 cotypeid

  data_type: 'integer'
  is_nullable: 0

=head2 cotype

  data_type: 'varchar'
  is_nullable: 1
  size: 35

=cut

__PACKAGE__->add_columns(
  "cotypeid",
  { data_type => "integer", is_nullable => 0 },
  "cotype",
  { data_type => "varchar", is_nullable => 1, size => 35 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cotypeid>

=back

=cut

__PACKAGE__->set_primary_key("cotypeid");

=head1 RELATIONS

=head2 coes

Type: has_many

Related object: L<IntelliShip::SchemaClass::Result::Co>

=cut

__PACKAGE__->has_many(
  "coes",
  "IntelliShip::SchemaClass::Result::Co",
  { "foreign.cotypeid" => "self.cotypeid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oyh8or9HnaY6mS44NusqVg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
