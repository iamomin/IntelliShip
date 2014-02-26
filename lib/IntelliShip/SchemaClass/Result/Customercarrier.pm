use utf8;
package IntelliShip::SchemaClass::Result::Customercarrier;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Customercarrier

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

=head1 TABLE: C<customercarrier>

=cut

__PACKAGE__->table("customercarrier");

=head1 ACCESSORS

=head2 customercarrierid

  data_type: 'integer'
  is_nullable: 0

=head2 customerid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 carrierid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 manifestemail

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 accountnumber

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=cut

__PACKAGE__->add_columns(
  "customercarrierid",
  { data_type => "integer", is_nullable => 0 },
  "customerid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "carrierid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "manifestemail",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "accountnumber",
  { data_type => "varchar", is_nullable => 1, size => 30 },
);

=head1 PRIMARY KEY

=over 4

=item * L</customercarrierid>

=back

=cut

__PACKAGE__->set_primary_key("customercarrierid");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3yBsogS6q/K+N+0rXU4t5w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
