use utf8;
package IntelliShip::SchemaClass::Result::Upsroutingcode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Upsroutingcode

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

=head1 TABLE: C<upsroutingcode>

=cut

__PACKAGE__->table("upsroutingcode");

=head1 ACCESSORS

=head2 countrycode

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 postalcodelow

  data_type: 'varchar'
  is_nullable: 1
  size: 7

=head2 postalcodehigh

  data_type: 'varchar'
  is_nullable: 1
  size: 7

=head2 urc

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=cut

__PACKAGE__->add_columns(
  "countrycode",
  { data_type => "char", is_nullable => 1, size => 2 },
  "postalcodelow",
  { data_type => "varchar", is_nullable => 1, size => 7 },
  "postalcodehigh",
  { data_type => "varchar", is_nullable => 1, size => 7 },
  "urc",
  { data_type => "varchar", is_nullable => 1, size => 12 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:f8m9yM0aKFXZ3eaLS6iFbg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
