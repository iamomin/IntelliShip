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

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

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
  { data_type => "char", is_nullable => 1, size => 13 },
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

# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:veT1q79kj87TCOubkM8TKg

__PACKAGE__->belongs_to(
	customer =>
		'IntelliShip::SchemaClass::Result::Customer',
		'customerid'
	);

__PACKAGE__->belongs_to(
	address =>
		'IntelliShip::SchemaClass::Result::Address',
		'addressid'
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
	return uc $full_name;
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
	my @arr = $self->restrictions->search({ fieldname => $field_name });
	push(@$field_values, $_->fieldvalue) foreach @arr;
	return $field_values;
	}

sub get_only_contact_data_value
	{
	my $self = shift;
	my $data_type_name = shift;
	my $data_type_id = shift;
	my $WHERE = { ownertypeid => '2', datatypename => $data_type_name };
	$WHERE->{datatypeid} = $data_type_id if $data_type_id;

	my @custcondata_objs = $self->customer_contact_data($WHERE, { order_by => 'ownertypeid desc' });

	my $contact_data_value;
	if (@custcondata_objs)
		{
		$contact_data_value = $_->value and last foreach @custcondata_objs;
		}
	return $contact_data_value;
	}

sub get_contact_data_value
	{
	my $self = shift;
	my $data_type_name = shift;
	my $data_type_id = shift;

	my $WHERE = { ownertypeid => '2', datatypename => $data_type_name };
	$WHERE->{datatypeid} = $data_type_id if $data_type_id;

	my @custcondata_objs = $self->customer_contact_data($WHERE, { order_by => 'ownertypeid desc' });

	my $contact_data_value;
	if (@custcondata_objs)
		{
		$contact_data_value = $_->value and last foreach @custcondata_objs;
		}
	else
		{
		$contact_data_value = $self->customer->get_contact_data_value($data_type_name) || '';
		}

	return $contact_data_value;
	}

sub show_only_my_items
	{
	my $self = shift;
	return $self->get_contact_data_value('myonly') || 0;
	}

sub login_level
	{
	my $self = shift;
	return $self->get_contact_data_value('loginlevel') || 0;
	}

sub is_superuser
	{
	my $self = shift;
	return ($self->get_contact_data_value('superuser') or $self->customer->superuser);
	}

sub is_administrator
	{
	my $self = shift;
	return ($self->get_contact_data_value('administrator') or $self->customer->administrator);
	}

sub default_package_type
	{
	my $self = shift;
	my $type = shift;
	$self->get_contact_data_value('defaultpackageunittype');
	}

sub default_product_type
	{
	my $self = shift;
	my $type = shift;
	$self->get_contact_data_value('defaultproductunittype');
	}

sub label_type
	{
	my $self = shift;
	return $self->get_contact_data_value('labeltype');
	}

sub label_port
	{
	my $self = shift;
	return $self->get_contact_data_value('labelport');
	}

sub default_packing_list
	{
	my $self = shift;
	return $self->get_contact_data_value('defaultpackinglist');
	}

sub default_thermal_count
	{
	my $self = shift;
	return $self->get_contact_data_value('defaultthermalcount') || 1;
	}

sub get_label_type
	{
	my $self = shift;
	my $LabelType = $self->label_type;
	$LabelType = $self->customer->label_type unless $LabelType;
	$LabelType = 'JPG' unless $LabelType;
	return $LabelType;
	}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
