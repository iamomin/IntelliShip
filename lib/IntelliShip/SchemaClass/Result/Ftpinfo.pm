use utf8;
package IntelliShip::SchemaClass::Result::Ftpinfo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Ftpinfo

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

=head1 TABLE: C<ftpinfo>

=cut

__PACKAGE__->table("ftpinfo");

=head1 ACCESSORS

=head2 ftpinfoid

  data_type: 'integer'
  is_nullable: 0

=head2 ftpinfotypeid

  data_type: 'integer'
  is_nullable: 1

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 path

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 address

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 active

  data_type: 'integer'
  is_nullable: 1

=head2 customer

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 timeout

  data_type: 'integer'
  is_nullable: 1

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 customerid

  data_type: 'char'
  is_nullable: 1
  size: 13

=cut

__PACKAGE__->add_columns(
  "ftpinfoid",
  { data_type => "integer", is_nullable => 0 },
  "ftpinfotypeid",
  { data_type => "integer", is_nullable => 1 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "path",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "address",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "active",
  { data_type => "integer", is_nullable => 1 },
  "customer",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "timeout",
  { data_type => "integer", is_nullable => 1 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "customerid",
  { data_type => "char", is_nullable => 1, size => 13 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ftpinfoid>

=back

=cut

__PACKAGE__->set_primary_key("ftpinfoid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m1g88bu+XkMrC+AJYAbYjw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
