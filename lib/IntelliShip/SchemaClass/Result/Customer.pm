use utf8;
package IntelliShip::SchemaClass::Result::Customer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Customer

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

=head1 TABLE: C<customer>

=cut

__PACKAGE__->table("customer");

=head1 ACCESSORS

=head2 customerid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 customername

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 contact

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 phone

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 fax

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 superuser

  data_type: 'integer'
  is_nullable: 1

=head2 ssnein

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 weighttype

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 aostype

  data_type: 'integer'
  is_nullable: 1

=head2 thirdpartybill

  data_type: 'integer'
  is_nullable: 1

=head2 administrator

  data_type: 'integer'
  is_nullable: 1

=head2 labelbanner

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 hasrates

  data_type: 'integer'
  is_nullable: 1

=head2 autoprint

  data_type: 'integer'
  is_nullable: 1

=head2 autoprocess

  data_type: 'integer'
  is_nullable: 1

=head2 batchprocess

  data_type: 'integer'
  is_nullable: 1

=head2 allowpostdating

  data_type: 'integer'
  is_nullable: 1

=head2 quickship

  data_type: 'integer'
  is_nullable: 1

=head2 datecreated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 defaultdeclaredvalue

  data_type: 'integer'
  is_nullable: 1

=head2 defaultfreightinsurance

  data_type: 'integer'
  is_nullable: 1

=head2 labelport

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 printthermalbol

  data_type: 'integer'
  is_nullable: 1

=head2 print8_5x11bol

  data_type: 'integer'
  is_nullable: 1

=head2 defaultthermalcount

  data_type: 'integer'
  is_nullable: 1

=head2 bolcount8_5x11

  data_type: 'integer'
  is_nullable: 1

=head2 extcustomerid

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 upsmanifestpage

  data_type: 'integer'
  is_nullable: 1

=head2 upsbooknumber

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 dhlunitid

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 autoreporttime

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 autoreportemail

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 autoreportinterval

  data_type: 'integer'
  is_nullable: 1

=head2 exportshipmenttab

  data_type: 'integer'
  is_nullable: 1

=head2 errorshipdate

  data_type: 'integer'
  is_nullable: 1

=head2 errorduedate

  data_type: 'integer'
  is_nullable: 1

=head2 uploadorders

  data_type: 'integer'
  is_nullable: 1

=head2 popproductdata

  data_type: 'integer'
  is_nullable: 1

=head2 zpl2

  data_type: 'integer'
  is_nullable: 1

=head2 boltype

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 quantityxweight

  data_type: 'integer'
  is_nullable: 1

=head2 reqcustnum

  data_type: 'integer'
  is_nullable: 1

=head2 reqponum

  data_type: 'integer'
  is_nullable: 1

=head2 reqproddescr

  data_type: 'integer'
  is_nullable: 1

=head2 reqdatetoship

  data_type: 'integer'
  is_nullable: 1

=head2 reqdateneeded

  data_type: 'integer'
  is_nullable: 1

=head2 smartaddressbook

  data_type: 'integer'
  is_nullable: 1

=head2 losspreventemail

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 proxyip

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 proxyport

  data_type: 'varchar'
  is_nullable: 1
  size: 5

=head2 halocustomerid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 autocsselect

  data_type: 'integer'
  is_nullable: 1

=head2 bolcountthermal

  data_type: 'integer'
  is_nullable: 1

=head2 hassecurity

  data_type: 'integer'
  is_nullable: 1

=head2 autoshipmentoptimize

  data_type: 'integer'
  is_nullable: 1

=head2 apiaosaddress

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 addressid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 amdelivery

  data_type: 'integer'
  is_nullable: 1

=head2 showhazardous

  data_type: 'integer'
  is_nullable: 1

=head2 chargediffthresholdtype

  data_type: 'varchar'
  is_nullable: 1
  size: 15

=head2 chargediffthreshold

  data_type: 'double precision'
  is_nullable: 1

=head2 losspreventemailordercreate

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 auxformaddressid

  data_type: 'char'
  is_nullable: 1
  size: 13

=cut

__PACKAGE__->add_columns(
  "customerid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "customername",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "contact",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "phone",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "fax",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "superuser",
  { data_type => "integer", is_nullable => 1 },
  "ssnein",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "weighttype",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "aostype",
  { data_type => "integer", is_nullable => 1 },
  "thirdpartybill",
  { data_type => "integer", is_nullable => 1 },
  "administrator",
  { data_type => "integer", is_nullable => 1 },
  "labelbanner",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "hasrates",
  { data_type => "integer", is_nullable => 1 },
  "autoprint",
  { data_type => "integer", is_nullable => 1 },
  "autoprocess",
  { data_type => "integer", is_nullable => 1 },
  "batchprocess",
  { data_type => "integer", is_nullable => 1 },
  "allowpostdating",
  { data_type => "integer", is_nullable => 1 },
  "quickship",
  { data_type => "integer", is_nullable => 1 },
  "datecreated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "defaultdeclaredvalue",
  { data_type => "integer", is_nullable => 1 },
  "defaultfreightinsurance",
  { data_type => "integer", is_nullable => 1 },
  "labelport",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "printthermalbol",
  { data_type => "integer", is_nullable => 1 },
  "print8_5x11bol",
  { data_type => "integer", is_nullable => 1 },
  "defaultthermalcount",
  { data_type => "integer", is_nullable => 1 },
  "bolcount8_5x11",
  { data_type => "integer", is_nullable => 1 },
  "extcustomerid",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "upsmanifestpage",
  { data_type => "integer", is_nullable => 1 },
  "upsbooknumber",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "dhlunitid",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "autoreporttime",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "autoreportemail",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "autoreportinterval",
  { data_type => "integer", is_nullable => 1 },
  "exportshipmenttab",
  { data_type => "integer", is_nullable => 1 },
  "errorshipdate",
  { data_type => "integer", is_nullable => 1 },
  "errorduedate",
  { data_type => "integer", is_nullable => 1 },
  "uploadorders",
  { data_type => "integer", is_nullable => 1 },
  "popproductdata",
  { data_type => "integer", is_nullable => 1 },
  "zpl2",
  { data_type => "integer", is_nullable => 1 },
  "boltype",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "quantityxweight",
  { data_type => "integer", is_nullable => 1 },
  "reqcustnum",
  { data_type => "integer", is_nullable => 1 },
  "reqponum",
  { data_type => "integer", is_nullable => 1 },
  "reqproddescr",
  { data_type => "integer", is_nullable => 1 },
  "reqdatetoship",
  { data_type => "integer", is_nullable => 1 },
  "reqdateneeded",
  { data_type => "integer", is_nullable => 1 },
  "smartaddressbook",
  { data_type => "integer", is_nullable => 1 },
  "losspreventemail",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "proxyip",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "proxyport",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "halocustomerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "autocsselect",
  { data_type => "integer", is_nullable => 1 },
  "bolcountthermal",
  { data_type => "integer", is_nullable => 1 },
  "hassecurity",
  { data_type => "integer", is_nullable => 1 },
  "autoshipmentoptimize",
  { data_type => "integer", is_nullable => 1 },
  "apiaosaddress",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "addressid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "amdelivery",
  { data_type => "integer", is_nullable => 1 },
  "showhazardous",
  { data_type => "integer", is_nullable => 1 },
  "chargediffthresholdtype",
  { data_type => "varchar", is_nullable => 1, size => 15 },
  "chargediffthreshold",
  { data_type => "double precision", is_nullable => 1 },
  "losspreventemailordercreate",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "auxformaddressid",
  { data_type => "char", is_nullable => 1, size => 13 },
);

=head1 PRIMARY KEY

=over 4

=item * L</customerid>

=back

=cut

__PACKAGE__->set_primary_key("customerid");

=head1 RELATIONS

=head2 coes

Type: has_many

Related object: L<IntelliShip::SchemaClass::Result::Co>

=cut

__PACKAGE__->has_many(
  "coes",
  "IntelliShip::SchemaClass::Result::Co",
  { "foreign.customerid" => "self.customerid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 producttypes

Type: has_many

Related object: L<IntelliShip::SchemaClass::Result::Producttype>

=cut

__PACKAGE__->has_many(
  "producttypes",
  "IntelliShip::SchemaClass::Result::Producttype",
  { "foreign.customerid" => "self.customerid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:R96fxv0S07o6j30zOYDqiA

__PACKAGE__->belongs_to(
	address =>
		'IntelliShip::SchemaClass::Result::Address',
		'addressid'
	);

__PACKAGE__->belongs_to(
	auxilary_address =>
		'IntelliShip::SchemaClass::Result::Address',
		'auxformaddressid'
	);

__PACKAGE__->has_many(
	contacts =>
		'IntelliShip::SchemaClass::Result::Contact',
		'customerid'
	);

__PACKAGE__->has_many(
	others =>
		'IntelliShip::SchemaClass::Result::Other',
		'customerid'
	);

__PACKAGE__->has_many(
	custcondata => 
		'IntelliShip::SchemaClass::Result::Custcondata',
		'ownerid'
	);

__PACKAGE__->has_many(
	droplist_data => 
		'IntelliShip::SchemaClass::Result::Droplistdata',
		{ "foreign.customerid" => "self.customerid" },
	);

__PACKAGE__->has_many(
	thirdpartyaccts => 
		'IntelliShip::SchemaClass::Result::Thirdpartyacct',
		{ "foreign.customerid" => "self.customerid" },
	);

__PACKAGE__->has_many(
	ucc128 =>
		'IntelliShip::SchemaClass::Result::Ucc128',
		{ "foreign.companyid" => "self.customerid" },
	);

__PACKAGE__->has_many(
	altsop =>
		'IntelliShip::SchemaClass::Result::Altsop',
		{ "foreign.companyid" => "self.customerid" },
	);

sub settings
	{
	my $self = shift;
	return $self->custcondata({ ownertypeid => '1' });
	}

sub get_contact_data_value
	{
	my $self = shift;
	my $data_type_name = shift;
	my $data_type_id = shift;

	my $WHERE = { ownertypeid => '1', datatypename => $data_type_name };
	$WHERE->{datatypeid} = $data_type_id if $data_type_id;

	my @custcondata_arr = $self->custcondata($WHERE);
	return unless @custcondata_arr;

	return $custcondata_arr[0]->value;
	}

sub login_level
	{
	my $self = shift;
	return $self->get_contact_data_value('loginlevel') || 0;
	}

sub has_extid_data
	{
	my $self = shift;
	my $MyDBI = shift;

	return unless $MyDBI;

	my $customer_id = $self->get_contact_data_value('sopid');
	$customer_id = $self->customerid unless $customer_id;


	my $sth = $MyDBI->select("SELECT 1 FROM droplistdata WHERE field = 'extid' AND customerid = '" . $customer_id . "'");
	return $sth->numrows;
	}

sub get_sop_id
	{
	my $self = shift;
	my $usealtsop = shift;
	my $extcustnum = shift;

	# Allow for alternate sopid's (customerid in customerservice - we can't change the field at this point)
	my $sop_id = $self->get_contact_data_value('sopid');
	$sop_id = $self->customerid unless $sop_id;

	# Check if the customer is capable of alt sops, and if this is a 3rd party shipment.  If so, check for new sopid.
	my ($using_altsop,$alt_sop_id) = (0,'');

	$usealtsop = $self->get_contact_data_value('usealtsop') unless $usealtsop;
	if ($usealtsop)
		{
		$extcustnum = $self->get_contact_data_value('extcustnum') unless $extcustnum;
		my $AltSOP  = $self->contact->model('MyDBI::Altsop')->new({});

		if (my $alt_sop_id = $AltSOP->get_alt_sopid($self->customerid,'extcustnum',$extcustnum))
			{
			$sop_id = $alt_sop_id;
			$using_altsop = 1;
			}
		}

	return $sop_id;
	}

sub third_party_account
	{
	my $self = shift;
	my $accountnumber = shift;

	return unless $accountnumber;

	my @thirdpartyaccts = $self->thirdpartyaccts;
	foreach my $ThirdPartyAcct (@thirdpartyaccts)
		{
		return $ThirdPartyAcct if uc $ThirdPartyAcct->tpacctnumber eq uc $accountnumber;
		}
	}

sub label_type
	{
	my $self = shift;
	return $self->get_contact_data_value('labeltype');
	}

sub get_alt_sopid
	{
	my $self = shift;
	my $key = shift;
	my $value = shift;
	return $self->altsop->select({ key => $key, value => $value });
	}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
