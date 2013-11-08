use utf8;
package IntelliShip::SchemaClass::Result::Myorderscolumnsassoc;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Myorderscolumnsassoc

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

=head1 TABLE: C<myorderscolumnsassoc>

=cut

__PACKAGE__->table("myorderscolumnsassoc");

=head1 ACCESSORS

=head2 myorderscolumnsassocid

  data_type: 'integer'
  is_nullable: 0

=head2 contactid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 myorderscolumnsid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 contactorder

  data_type: 'integer'
  is_nullable: 1

=head2 defaultsort

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
#  "myorderscolumnsassocid",
#  { data_type => "integer", is_nullable => 0 },
  "contactid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "myorderscolumnsid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "contactorder",
  { data_type => "integer", is_nullable => 1 },
  "defaultsort",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</myorderscolumnsassocid>

=back

=cut

#__PACKAGE__->set_primary_key("myorderscolumnsassocid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CbB3w0EWxZDDp1SQ7/GAsQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
