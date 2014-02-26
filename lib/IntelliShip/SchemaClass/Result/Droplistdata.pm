use utf8;
package IntelliShip::SchemaClass::Result::Droplistdata;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Droplistdata

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

=head1 TABLE: C<droplistdata>

=cut

__PACKAGE__->table("droplistdata");

=head1 ACCESSORS

=head2 droplistdataid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 customerid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 field

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 fieldvalue

  data_type: 'text'
  is_nullable: 1

=head2 fieldtext

  data_type: 'text'
  is_nullable: 1

=head2 fieldorder

  data_type: 'integer'
  is_nullable: 1

=head2 datemodified

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "droplistdataid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "customerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "field",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "fieldvalue",
  { data_type => "text", is_nullable => 1 },
  "fieldtext",
  { data_type => "text", is_nullable => 1 },
  "fieldorder",
  { data_type => "integer", is_nullable => 1 },
  "datemodified",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</droplistdataid>

=back

=cut

__PACKAGE__->set_primary_key("droplistdataid");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kHYkrFvtEFyRac1CRxAzew


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
