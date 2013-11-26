use utf8;
package IntelliShip::SchemaClass::Result::Contact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Contact

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

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<contact>

=cut

__PACKAGE__->table("contact");

=head1 ACCESSORS

=head2 contactid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 customerid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 firstname

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 lastname

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 phonemobile

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 phonebusiness

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 datecreated

  data_type: 'date'
  is_nullable: 1

=head2 datedeactivated

  data_type: 'date'
  is_nullable: 1

=head2 primarycontact

  data_type: 'integer'
  is_nullable: 1

=head2 domain

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 fax

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 department

  data_type: 'varchar'
  is_nullable: 1
  size: 75

=head2 phonehome

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 addressid

  data_type: 'varchar'
  is_nullable: 1
  size: 13

=cut

__PACKAGE__->add_columns(
  "contactid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "customerid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "firstname",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "lastname",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "phonemobile",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "phonebusiness",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "datecreated",
  { data_type => "date", is_nullable => 1 },
  "datedeactivated",
  { data_type => "date", is_nullable => 1 },
  "primarycontact",
  { data_type => "integer", is_nullable => 1 },
  "domain",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "fax",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "department",
  { data_type => "varchar", is_nullable => 1, size => 75 },
  "phonehome",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "addressid",
  { data_type => "varchar", is_nullable => 1, size => 13 },
);

=head1 PRIMARY KEY

=over 4

=item * L</contactid>

=back

=cut

__PACKAGE__->set_primary_key("contactid");

# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:goqKXBZlzSALbGBy6A4Scw

__PACKAGE__->has_one(
	customer =>
		'IntelliShip::SchemaClass::Result::Customer',
		'customerid'
	);

__PACKAGE__->has_many(
	restrictions => 
		'IntelliShip::SchemaClass::Result::Restrictcontact',
		'contactid'
	);

__PACKAGE__->has_many(
	customer_contact_data => 
		'IntelliShip::SchemaClass::Result::Custcondata',
		'ownerid'
	);

sub full_name
	{
	my $self = shift;
	my $full_name = $self->firstname;
	$full_name .=  ' ' . $self->lastname if $self->lastname;
	$full_name = $self->username unless $full_name;
	$full_name = $self->customer->customername unless $full_name;
	$full_name = $self->customer->username unless $full_name;
	return $full_name;
	}

sub is_restricted
	{
	my $self = shift;
	my $restrict_contact_rs = $self->restrictions;
	return $restrict_contact_rs->count;
	}

sub get_restricted_values
	{
	my $self = shift;
	my $field_name = shift;
	my $field_values = [];
	my @arr = $self->restrictions;
	$_->fieldname =~ /$field_name/ and push(@$field_values, $_->fieldvalue) foreach @arr;
	return $field_values;
	}

sub get_contact_data_value
	{
	my $self = shift;
	my $data_type_name = shift;
	my $data_type_id = shift;

	my $WHERE = { ownertypeid => ['1','2'], datatypename => $data_type_name };
	$WHERE->{datatypeid} = $data_type_id if $data_type_id;

	my @custcondata_objs = $self->customer_contact_data($WHERE);

	my $contact_data_value;
	$contact_data_value = $_->value and last foreach @custcondata_objs;

	return $contact_data_value;
	}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
