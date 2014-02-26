use utf8;
package IntelliShip::SchemaClass::Result::Producttype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Producttype

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

=head1 TABLE: C<producttype>

=cut

__PACKAGE__->table("producttype");

=head1 ACCESSORS

=head2 producttypeid

  data_type: 'integer'
  is_nullable: 0

=head2 customerid

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 13

=head2 producttype

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 producttypedescr

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 declaredvalue

  data_type: 'double precision'
  is_nullable: 1

=head2 caseqty

  data_type: 'integer'
  is_nullable: 1

=head2 palletqty

  data_type: 'integer'
  is_nullable: 1

=head2 caseweight

  data_type: 'integer'
  is_nullable: 1

=head2 caselength

  data_type: 'integer'
  is_nullable: 1

=head2 casewidth

  data_type: 'integer'
  is_nullable: 1

=head2 casedepth

  data_type: 'integer'
  is_nullable: 1

=head2 palletlength

  data_type: 'integer'
  is_nullable: 1

=head2 palletwidth

  data_type: 'integer'
  is_nullable: 1

=head2 defaulttype

  data_type: 'integer'
  is_nullable: 1

=head2 palletheight

  data_type: 'integer'
  is_nullable: 1

=head2 class

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "producttypeid",
  { data_type => "integer", is_nullable => 0 },
  "customerid",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 13 },
  "producttype",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "producttypedescr",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "declaredvalue",
  { data_type => "double precision", is_nullable => 1 },
  "caseqty",
  { data_type => "integer", is_nullable => 1 },
  "palletqty",
  { data_type => "integer", is_nullable => 1 },
  "caseweight",
  { data_type => "integer", is_nullable => 1 },
  "caselength",
  { data_type => "integer", is_nullable => 1 },
  "casewidth",
  { data_type => "integer", is_nullable => 1 },
  "casedepth",
  { data_type => "integer", is_nullable => 1 },
  "palletlength",
  { data_type => "integer", is_nullable => 1 },
  "palletwidth",
  { data_type => "integer", is_nullable => 1 },
  "defaulttype",
  { data_type => "integer", is_nullable => 1 },
  "palletheight",
  { data_type => "integer", is_nullable => 1 },
  "class",
  { data_type => "varchar", is_nullable => 1, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</producttypeid>

=back

=cut

__PACKAGE__->set_primary_key("producttypeid");

=head1 RELATIONS

=head2 customerid

Type: belongs_to

Related object: L<IntelliShip::SchemaClass::Result::Customer>

=cut

__PACKAGE__->belongs_to(
  "customerid",
  "IntelliShip::SchemaClass::Result::Customer",
  { customerid => "customerid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DBOYyaJQFV0zaIN2arMFuw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
