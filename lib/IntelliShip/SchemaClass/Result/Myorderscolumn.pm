use utf8;
package IntelliShip::SchemaClass::Result::Myorderscolumn;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Myorderscolumn

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

=head1 TABLE: C<myorderscolumns>

=cut

__PACKAGE__->table("myorderscolumns");

=head1 ACCESSORS

=head2 myorderscolumnsid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 defaultorder

  data_type: 'integer'
  is_nullable: 1

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 varname

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=head2 defaultsort

  data_type: 'integer'
  is_nullable: 1

=head2 cotypeid

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "myorderscolumnsid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "defaultorder",
  { data_type => "integer", is_nullable => 1 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "varname",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "defaultsort",
  { data_type => "integer", is_nullable => 1 },
  "cotypeid",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</myorderscolumnsid>

=back

=cut

__PACKAGE__->set_primary_key("myorderscolumnsid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AA0QC9+j3EsnzplyQRNrQg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
