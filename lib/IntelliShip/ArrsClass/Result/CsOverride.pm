use utf8;
package IntelliShip::ArrsClass::Result::CsOverride;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::CsOverride

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

=head1 TABLE: C<csoverride>

=cut

__PACKAGE__->table("csoverride");

=head1 ACCESSORS

=head2 csoverrideid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 customerid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 customerserviceid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 datatypeid

  data_type: 'integer'
  is_nullable: 1

=head2 datatypename

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 value

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "csoverrideid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "customerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "customerserviceid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "datatypeid",
  { data_type => "integer", is_nullable => 1 },
  "datatypename",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "value",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</csoverrideid>

=back

=cut

__PACKAGE__->set_primary_key("csoverrideid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:L8afv00Pv9wIT2D7pN9Wbg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
