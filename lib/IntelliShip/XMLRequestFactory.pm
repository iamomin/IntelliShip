package IntelliShip::XMLRequestFactory;

use strict;
use LWP::UserAgent;
use HTTP::Request::Common;

=pod

=head1 NAME

IntelliShip::XMLRequestFactory

=head1 DESCRIPTION

Collection of various utilitarian methods.

=head1 METHODS

=cut

sub new
	{
	my $self = shift;
	my $obref = {};

	bless $obref, $self;

	return $obref;
	}

#
#	my $hash = IntelliShip::XMLRequestFactory->GetCarrierServiceName('0000000000430');
#
sub GetCarrierServiceName
	{
	my $self = shift;
	my $csid = shift;

	my $hash = $self->APIRequest({action => 'GetCarrierServiceName', csid => '0000000000430'});

	return $hash;
	}

sub APIRequest
	{
	my $self = shift;
	my $request = shift;

	my $arrs_path = '/opt/engage/arrs';
	if ( -r "$arrs_path/lib/ARRS.pm" )
		{
		eval "use lib '$arrs_path/lib'";
		eval "use ARRS";

		my $ARRS = new ARRS();
		return $ARRS->APICall($request);
		}
	else
		{
		$request->{'screen'} = 'api';
		$request->{'username'} = 'engage';
		$request->{'password'} = 'ohila4';
		$request->{'httpurl'} = "http://darrs.engagetechnology.com";

	#	my $mode = IntelliShip::MyConfig->getDomain;
    #
	#	if ( hostname() eq 'rml00web01' )
	#		{
	#		$request->{'httpurl'} = "http://drarrs.$config->{BASE_DOMAIN}";
	#		}
	#	elsif ( hostname() eq 'rml01web01' )
	#		{
	#		$request->{'httpurl'} = "http://rarrs.$config->{BASE_DOMAIN}";
	#		}
	#	elsif ( &GetServerType == 3 )
	#		{
	#		$request->{'httpurl'} = "http://darrs.$config->{BASE_DOMAIN}";
	#		}
	#	else
	#		{
	#		$request->{'httpurl'} = "http://arrs.$config->{BASE_DOMAIN}";
	#		}

		my $UserAgent = LWP::UserAgent->new();

		my $host_response = $UserAgent->request(
				POST $request->{'httpurl'},
				Content_Type	=>	'form-data',
				Content			=>	[%$request]
		);

		$host_response->remove_header($host_response->header_field_names);
		return $self->convert_response_to_ref($host_response->as_string);
		}
	}

sub convert_response_to_ref
	{
	my $self = shift;
	my $host_response = shift;
	my $response = {};

	my @Lines = split(/\n/,$host_response);

	while (@Lines)
		{
		my $Line = shift(@Lines);
		my ($Key,$Value) = $Line =~ /(\w+): (.*)/;

		if ( defined($Value) && $Value ne '' )
			{
			$response->{$Key} = $Value;
			}
		}

	return $response;
	}


1;

__END__