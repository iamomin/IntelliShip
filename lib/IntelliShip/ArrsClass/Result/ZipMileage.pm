use utf8;
package IntelliShip::ArrsClass::Result::ZipMileage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::ZipMileage

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

=head1 TABLE: C<zipmileage>

=cut

__PACKAGE__->table("zipmileage");

=head1 ACCESSORS

=head2 zipmileageid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 origin

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 dest

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 mileage

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "zipmileageid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "origin",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "dest",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "mileage",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</zipmileageid>

=back

=cut

__PACKAGE__->set_primary_key("zipmileageid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RWlF+IGj5u/Xz9WA1vdnhw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
