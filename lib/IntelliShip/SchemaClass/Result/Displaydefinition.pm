use utf8;
package IntelliShip::SchemaClass::Result::Displaydefinition;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Displaydefinition

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

=head1 TABLE: C<displaydefinitions>

=cut

__PACKAGE__->table("displaydefinitions");

=head1 ACCESSORS

=head2 displaydefinitionsid

  data_type: 'integer'
  is_nullable: 0

=head2 varname

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=head2 customerid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 displayname

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=head2 required

  data_type: 'integer'
  is_nullable: 1

=head2 visible

  data_type: 'integer'
  is_nullable: 1

=head2 displaysize

  data_type: 'integer'
  is_nullable: 1

=head2 maxlength

  data_type: 'integer'
  is_nullable: 1

=head2 loginlevel

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
#  "displaydefinitionsid",
#  { data_type => "integer", is_nullable => 0 },
  "varname",
  { data_type => "varchar", is_nullable => 0, size => 30 },
  "customerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "displayname",
  { data_type => "varchar", is_nullable => 0, size => 30 },
  "required",
  { data_type => "integer", is_nullable => 1 },
  "visible",
  { data_type => "integer", is_nullable => 1 },
  "displaysize",
  { data_type => "integer", is_nullable => 1 },
  "maxlength",
  { data_type => "integer", is_nullable => 1 },
  "loginlevel",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</displaydefinitionsid>

=back

=cut

#__PACKAGE__->set_primary_key("displaydefinitionsid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HBdxuZVTV36d604Tm3c8Cg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
