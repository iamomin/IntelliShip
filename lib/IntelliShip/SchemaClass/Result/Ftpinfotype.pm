use utf8;
package IntelliShip::SchemaClass::Result::Ftpinfotype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Ftpinfotype

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

=head1 TABLE: C<ftpinfotype>

=cut

__PACKAGE__->table("ftpinfotype");

=head1 ACCESSORS

=head2 ftpinfotypeid

  data_type: 'integer'
  is_nullable: 0

=head2 ftpinfotypename

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=cut

__PACKAGE__->add_columns(
  "ftpinfotypeid",
  { data_type => "integer", is_nullable => 0 },
  "ftpinfotypename",
  { data_type => "varchar", is_nullable => 0, size => 30 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ftpinfotypeid>

=back

=cut

__PACKAGE__->set_primary_key("ftpinfotypeid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MaO3HmG2Nvq7zJhTAB5hKw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
