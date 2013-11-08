use utf8;
package IntelliShip::SchemaClass::Result::Freightcharge;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Freightcharge

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

=head1 TABLE: C<freightcharges>

=cut

__PACKAGE__->table("freightcharges");

=head1 ACCESSORS

=head2 freightchargesid

  data_type: 'integer'
  is_nullable: 0

=head2 freightcharges

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "freightchargesid",
  { data_type => "integer", is_nullable => 0 },
  "freightcharges",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</freightchargesid>

=back

=cut

__PACKAGE__->set_primary_key("freightchargesid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gJYONVlV9tS2/H8qFePjqA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
