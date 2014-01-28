use utf8;
package IntelliShip::SchemaClass::Result::Address;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Address

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

=head1 TABLE: C<address>

=cut

__PACKAGE__->table("address");

=head1 ACCESSORS

=head2 addressid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 addressnamecode

  data_type: 'varchar'
  is_nullable: 1
  size: 75

=head2 addresscode

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 addressname

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 address1

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 address2

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 city

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 state

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 zip

  data_type: 'varchar'
  is_nullable: 1
  size: 35

=head2 country

  data_type: 'char'
  is_nullable: 1
  size: 2

=cut

__PACKAGE__->add_columns(
  "addressid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "addressnamecode",
  { data_type => "varchar", is_nullable => 1, size => 75 },
  "addresscode",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "addressname",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "address1",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "address2",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "city",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "state",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "zip",
  { data_type => "varchar", is_nullable => 1, size => 35 },
  "country",
  { data_type => "char", is_nullable => 1, size => 2 },
);

=head1 PRIMARY KEY

=over 4

=item * L</addressid>

=back

=cut

__PACKAGE__->set_primary_key("addressid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uN5QXmhnfe3ygqqj8Hld/Q

__PACKAGE__->belongs_to(
	country_details => 
		"IntelliShip::SchemaClass::Result::Country",
		{'foreign.countryiso2' => 'self.country'},
		{ join_type => 'inner' },
	);

sub insert
	{
	my $self = shift;
	my @args = @_;
	$self->set_address_code_details;
	$self->next::method(@args);
	return $self;
	}

sub update
	{
	my $self = shift;
	my @args = @_;
	$self->set_address_code_details;
	$self->next::method(@args);
	return $self;
	}

sub set_address_code_details
	{
	my $self = shift;

	my $addressname = $self->addressname;
	my $string = $self->address1.$self->address2.$self->city.$self->state.$self->zip;
	my $addresscountry = $self->country;

	my $addressinitial = substr($addressname,0,1) if $addressname;
	$addressname = substr($addressname,1) if $addressname;

	$addressname = uc($addressname);
	$addressname =~ s/ //g;
	$addressname =~ s/[^a-zA-Z0-9]+//gs;
	$addressname =~ s/A//g;
	$addressname =~ s/E//g;
	$addressname =~ s/I//g;
	$addressname =~ s/O//g;
	$addressname =~ s/U//g;
	$addressname =~ s/(\D)\1+/$1/g;

	$string = uc($string);
	$string =~ s/ //g;
	$string =~ s/[^a-zA-Z0-9]+//gs;
	$string =~ s/A//g;
	$string =~ s/E//g;
	$string =~ s/I//g;
	$string =~ s/O//g;
	$string =~ s/U//g;
	$string =~ s/(\D)\1+/$1/g;

	my $addressnamecode = $addressinitial.$addressname;
	my $addresscode = $string.$addresscountry;

	if ( length($addresscode) <= 10 && length($addresscode) != 0 && $addresscode ne 'US')
		{
		my $uniqueid = $self->addressid;
		$addresscode = $uniqueid.$addresscode;
		}

	$self->addressnamecode($addressnamecode);
	$self->addresscode($addresscode);
	}

sub country_description
	{
	my $self = shift;
	my $CountryObj = $self->country_details;
	return $CountryObj->countryname;
	}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
