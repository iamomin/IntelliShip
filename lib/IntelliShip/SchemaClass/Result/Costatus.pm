use utf8;
package IntelliShip::SchemaClass::Result::Costatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Costatus

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

=head1 TABLE: C<costatus>

=cut

__PACKAGE__->table("costatus");

=head1 ACCESSORS

=head2 statusid

  data_type: 'integer'
  is_nullable: 0

=head2 costatusname

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=cut

__PACKAGE__->add_columns(
  "statusid",
  { data_type => "integer", is_nullable => 0 },
  "costatusname",
  { data_type => "varchar", is_nullable => 1, size => 250 },
);

=head1 PRIMARY KEY

=over 4

=item * L</statusid>

=back

=cut

__PACKAGE__->set_primary_key("statusid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4wGb/3cXZD63ib4cW4wRug


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
