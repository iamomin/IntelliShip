use utf8;
package IntelliShip::ArrsClass::Result::InvoiceData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::InvoiceData

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

=head1 TABLE: C<invoicedata>

=cut

__PACKAGE__->table("invoicedata");

=head1 ACCESSORS

=head2 invoicedataid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 sopid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 carrierid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 invoicedate

  data_type: 'date'
  is_nullable: 0

=head2 batchnumber

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 datecreated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 freightcharges

  data_type: 'real'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "invoicedataid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "sopid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "carrierid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "invoicedate",
  { data_type => "date", is_nullable => 0 },
  "batchnumber",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "datecreated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "freightcharges",
  { data_type => "real", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</invoicedataid>

=back

=cut

__PACKAGE__->set_primary_key("invoicedataid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:N8oEyqe/9INQZf6TzxfOqA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
