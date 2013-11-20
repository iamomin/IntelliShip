use utf8;
package IntelliShip::ArrsClass::Result::DhlOnForward;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::DhlOnForward

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

=head1 TABLE: C<dhlonforward>

=cut

__PACKAGE__->table("dhlonforward");

=head1 ACCESSORS

=head2 originpostalcode

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 destinpostalcode

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 city

  data_type: 'varchar'
  is_nullable: 1
  size: 35

=head2 countrycode

  data_type: 'char'
  is_nullable: 1
  size: 2

=cut

__PACKAGE__->add_columns(
  "originpostalcode",
  { data_type => "varchar", is_nullable => 1, size => 12 },
  "destinpostalcode",
  { data_type => "varchar", is_nullable => 1, size => 12 },
  "city",
  { data_type => "varchar", is_nullable => 1, size => 35 },
  "countrycode",
  { data_type => "char", is_nullable => 1, size => 2 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C55HxVYlKnXoNukdrwGEkw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
