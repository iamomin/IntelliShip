use utf8;
package IntelliShip::SchemaClass::Result::Thirdpartyacct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Thirdpartyacct

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

=head1 TABLE: C<thirdpartyacct>

=cut

__PACKAGE__->table("thirdpartyacct");

=head1 ACCESSORS

=head2 thirdpartyacctid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 tpacctnumber

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=head2 tpcompanyname

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 tpaddress1

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 tpaddress2

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 tpcity

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 tpstate

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 tpzip

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 tpcountry

  data_type: 'char'
  is_nullable: 0
  size: 2

=head2 customerid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 contactname

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 contactphone

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=cut

__PACKAGE__->add_columns(
  "thirdpartyacctid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "tpacctnumber",
  { data_type => "varchar", is_nullable => 0, size => 30 },
  "tpcompanyname",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "tpaddress1",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "tpaddress2",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "tpcity",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "tpstate",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "tpzip",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "tpcountry",
  { data_type => "char", is_nullable => 0, size => 2 },
  "customerid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "contactname",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "contactphone",
  { data_type => "varchar", is_nullable => 1, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</thirdpartyacctid>

=back

=cut

__PACKAGE__->set_primary_key("thirdpartyacctid");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WPNSEmTJpSGwIgklQZVnxQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
