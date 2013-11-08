use utf8;
package IntelliShip::SchemaClass::Result::Altsopservice;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Altsopservice

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

=head1 TABLE: C<altsopservice>

=cut

__PACKAGE__->table("altsopservice");

=head1 ACCESSORS

=head2 altsopserviceid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 customerid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 serviceid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 carrier

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 modetype

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 transittime

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "altsopserviceid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "customerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "serviceid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "carrier",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "modetype",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "transittime",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</altsopserviceid>

=back

=cut

__PACKAGE__->set_primary_key("altsopserviceid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EOEAa0Nq4+bOyRQoqycdnw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
