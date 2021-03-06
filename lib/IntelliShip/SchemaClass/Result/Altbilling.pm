use utf8;
package IntelliShip::SchemaClass::Result::Altbilling;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Altbilling

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

=head1 TABLE: C<altbilling>

=cut

__PACKAGE__->table("altbilling");

=head1 ACCESSORS

=head2 altbillingid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 key

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 value

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 carrierid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 billingaccount

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 meternumber

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "altbillingid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "key",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "value",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "carrierid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "billingaccount",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "meternumber",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</altbillingid>

=back

=cut

__PACKAGE__->set_primary_key("altbillingid");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EkA7gMdrrJfNVIgLBRxzKw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
