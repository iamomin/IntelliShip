use utf8;
package IntelliShip::ArrsClass::Result::DhlusCityZipSVC;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::DhlusCityZipSVC

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

=head1 TABLE: C<dhluscityzipsvc>

=cut

__PACKAGE__->table("dhluscityzipsvc");

=head1 ACCESSORS

=head2 postalcode

  data_type: 'integer'
  is_nullable: 1

=head2 city

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 state

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 serviceareacode

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 servicestandard

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 airplusdays

  data_type: 'varchar'
  is_nullable: 1
  size: 2

=head2 groundoriginplusdays

  data_type: 'integer'
  is_nullable: 1

=head2 grounddestinplusdays

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "postalcode",
  { data_type => "integer", is_nullable => 1 },
  "city",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "state",
  { data_type => "char", is_nullable => 1, size => 2 },
  "serviceareacode",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "servicestandard",
  { data_type => "char", is_nullable => 1, size => 2 },
  "airplusdays",
  { data_type => "varchar", is_nullable => 1, size => 2 },
  "groundoriginplusdays",
  { data_type => "integer", is_nullable => 1 },
  "grounddestinplusdays",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dzwIaaCK3jZqOEBYHyELjw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
