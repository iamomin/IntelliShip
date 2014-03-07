use utf8;
package IntelliShip::SchemaClass::Result::Productsku;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Productsku

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

=head1 TABLE: C<productsku>

=cut

__PACKAGE__->table("productsku");

=head1 ACCESSORS

=head2 productskuid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 customerid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 customerskuid

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 customerclientskuid

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 upccode

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 value

  data_type: 'double precision'
  is_nullable: 1

=head2 manufacturecountry

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 hazardous

  data_type: 'integer'
  is_nullable: 1

=head2 weight

  data_type: 'double precision'
  is_nullable: 1

=head2 weighttype

  data_type: 'integer'
  is_nullable: 1

=head2 length

  data_type: 'double precision'
  is_nullable: 1

=head2 width

  data_type: 'double precision'
  is_nullable: 1

=head2 height

  data_type: 'double precision'
  is_nullable: 1

=head2 dimtype

  data_type: 'integer'
  is_nullable: 1

=head2 skupercase

  data_type: 'integer'
  is_nullable: 1

=head2 caseweight

  data_type: 'double precision'
  is_nullable: 1

=head2 caseweighttype

  data_type: 'integer'
  is_nullable: 1

=head2 caselength

  data_type: 'double precision'
  is_nullable: 1

=head2 casewidth

  data_type: 'double precision'
  is_nullable: 1

=head2 caseheight

  data_type: 'double precision'
  is_nullable: 1

=head2 casedimtype

  data_type: 'integer'
  is_nullable: 1

=head2 casesperpallet

  data_type: 'integer'
  is_nullable: 1

=head2 palletweight

  data_type: 'double precision'
  is_nullable: 1

=head2 palletweighttype

  data_type: 'integer'
  is_nullable: 1

=head2 palletlength

  data_type: 'double precision'
  is_nullable: 1

=head2 palletwidth

  data_type: 'double precision'
  is_nullable: 1

=head2 palletheight

  data_type: 'double precision'
  is_nullable: 1

=head2 palletdimtype

  data_type: 'integer'
  is_nullable: 1

=head2 nmfc

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 class

  data_type: 'double precision'
  is_nullable: 1

=head2 unitofmeasure

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 balanceonhand

  data_type: 'integer'
  is_nullable: 1

=head2 unittypeid

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "productskuid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "customerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "customerskuid",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "customerclientskuid",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "upccode",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "value",
  { data_type => "double precision", is_nullable => 1 },
  "manufacturecountry",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "hazardous",
  { data_type => "integer", is_nullable => 1 },
  "weight",
  { data_type => "double precision", is_nullable => 1 },
  "weighttype",
  { data_type => "integer", is_nullable => 1 },
  "length",
  { data_type => "double precision", is_nullable => 1 },
  "width",
  { data_type => "double precision", is_nullable => 1 },
  "height",
  { data_type => "double precision", is_nullable => 1 },
  "dimtype",
  { data_type => "integer", is_nullable => 1 },
  "skupercase",
  { data_type => "integer", is_nullable => 1 },
  "caseweight",
  { data_type => "double precision", is_nullable => 1 },
  "caseweighttype",
  { data_type => "integer", is_nullable => 1 },
  "caselength",
  { data_type => "double precision", is_nullable => 1 },
  "casewidth",
  { data_type => "double precision", is_nullable => 1 },
  "caseheight",
  { data_type => "double precision", is_nullable => 1 },
  "casedimtype",
  { data_type => "integer", is_nullable => 1 },
  "casesperpallet",
  { data_type => "integer", is_nullable => 1 },
  "palletweight",
  { data_type => "double precision", is_nullable => 1 },
  "palletweighttype",
  { data_type => "integer", is_nullable => 1 },
  "palletlength",
  { data_type => "double precision", is_nullable => 1 },
  "palletwidth",
  { data_type => "double precision", is_nullable => 1 },
  "palletheight",
  { data_type => "double precision", is_nullable => 1 },
  "palletdimtype",
  { data_type => "integer", is_nullable => 1 },
  "nmfc",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "class",
  { data_type => "double precision", is_nullable => 1 },
  "unitofmeasure",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "balanceonhand",
  { data_type => "integer", is_nullable => 1 },
  "unittypeid",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</productskuid>

=back

=cut

__PACKAGE__->set_primary_key("productskuid");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TMdZ+j78SX74R3YvsSxbQw

__PACKAGE__->belongs_to(
	unittype =>
		'IntelliShip::SchemaClass::Result::Unittype',
		{ 'foreign.unittypeid' => 'self.unittypeid' }
	);

sub unittypedescription
	{
	my $self = shift;
	my $UnitType = $self->unittype;
	return $UnitType->unittypename if $UnitType;
	}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
