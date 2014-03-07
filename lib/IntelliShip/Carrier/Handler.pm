package IntelliShip::Carrier::Handler;

use Moose;
use Data::Dumper;
use IntelliShip::Carrier::Response;
use IntelliShip::Carrier::Constants;

BEGIN {
	has 'CO' => ( is => 'rw' );
	has 'SHIPMENT' => ( is => 'rw' );
	has 'token' => ( is => 'rw' );
	has 'context' => ( is => 'rw' );
	has 'carrier' => ( is => 'rw' );
	has 'customer' => ( is => 'rw' );
	has 'customerservice' => ( is => 'rw' );
	has 'service' => ( is => 'rw' );
	has 'request_data' => ( is => 'rw' );
	has 'request_type' => ( is => 'rw' );
	}

my $carriers = {
	'UPS' => &CARRIER_UPS,
	'USPS' => &CARRIER_USPS,
	'FEDEX' => &CARRIER_FEDEX,
	};

sub model
	{
	my $self = shift;
	my $model = shift;

	if ($self->context)
		{
		return $self->context->model($model);
		}
	}

sub myDBI
	{
	my $self = shift;
	return $self->model('MyDBI');
	}


sub process_request
	{
	my $self = shift;
	my $input_hash = shift;

	###############################################
	# GET INPUT
	###############################################
	my $context = $input_hash->{'CONTEXT'};
	my $myDBI   = $input_hash->{'MYDBI'};

	###############################################
	# SETUP RESPONSE OBJECT
	###############################################
	my $Response = IntelliShip::Carrier::Response->new;

	$context = $self->context unless $context;

	unless ($context)
		{
		$Response->message('Accessed is denied. Invalid request context');
		$Response->response_code('100');
		return $Response;
		}

	###############################################
	# SETUP DB CONNECTION
	###############################################
	$myDBI   = $self->myDBI unless $myDBI;

	unless ($myDBI)
		{
		$Response->message('Accessed is denied. Invalid DB');
		$Response->response_code('101');
		return $Response;
		}

	###############################################
	# AUTHORIZE CUSTOMER USER
	###############################################

	my $userProfile;

	unless ($input_hash->{'NO_TOKEN_OPTION'})
		{
		unless ($self->token)
			{
			$Response->message('Accessed is denied. Invalid token');
			$Response->response_code('102');
			return $Response;
			}

		unless (my $Token = $self->model('MyDBI::Token')->find({ tokenid => $self->tokenid}))
			{
			$Response->message('Accessed is denied. Invalid token');
			$Response->response_code('103');
			return $Response;
			}
		}

	unless ($self->carrier)
		{
		$Response->message('Accessed is denied. Invalid Carrier Name');
		$Response->response_code('104');
		return $Response;
		}

	unless ($self->request_type)
		{
		$Response->message('Accessed is denied. Invalid Request Type');
		$Response->response_code('105');
		return $Response;
		}

	###############################################
	# IDENTIFY TRANSACTION BROKER
	###############################################
	my $DriverModule = "IntelliShip::Carrier::Driver::" . $carriers->{uc $self->carrier} . "::" . $self->request_type;

	#print STDERR "\n... CARRIER DRIVER MODULE: " . $DriverModule;

	eval "use $DriverModule;";

	if ($@)
		{
		print STDERR "\n$@\n";
		$Response->message($@);
		$Response->response_code('106');
		return $Response;
		}

	###############################################
	# CALL BROKER AND POPULATE REQUEST INFO
	###############################################

	my $Driver = $DriverModule->new;
	$Driver->response($Response);
	$Driver->DB_ref($myDBI);
	$Driver->CO($self->CO);
	$Driver->SHIPMENT($self->SHIPMENT);
	$Driver->customerservice($self->customerservice);
	$Driver->service($self->service);
	$Driver->context($self->context);
	$Driver->customer($self->customer);
	$Driver->data($self->request_data);

	###############################################
	# GET POPULATED RESPONSE OBJECT
	###############################################

	eval {
	$Driver->process_request;
	};

	if ($@)
		{
		print STDERR "\n... process_request ERROR: " . $@;
		my $error_detail = $@;
		chomp $error_detail;
		$Response->message($error_detail);
		$Response->response_code('107');
		return $Response;
		}

	if ($Driver->has_errors)
		{
		$Response->message($Driver->error_string);
		$Response->response_code('108');
		return $Response;
		}

	$Response->response_code('0');
	$Response->is_success(1);

	return $Response;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__