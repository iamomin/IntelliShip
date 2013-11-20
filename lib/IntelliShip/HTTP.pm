package IntelliShip::HTTP;

use Mouse;
use HTTP::Request;
use LWP::UserAgent;
use IntelliShip::Utils;

extends 'IntelliShip::Errors';

has 'username'			=> ( is => 'rw' );
has 'password'			=> ( is => 'rw' );
has 'request_content'	=> ( is => 'rw' );
has 'content_type'		=> ( is => 'rw' );
has 'response_content'	=> ( is => 'rw' );
has 'connection_type'	=> ( is => 'rw' );
has 'timeout'			=> ( is => 'rw' );
has 'method'			=> ( is => 'rw' );
has 'host_production'	=> ( is => 'rw' );
has 'uri_production'	=> ( is => 'rw' );
has 'SSL_connector'		=> ( is => 'rw' );

sub new
	{
	my $self = shift;
	my $obref = $self->SUPER::new(@_);
	return $obref;
	}

sub send
	{
	my $self = shift;

	return undef if (!$self->is_valid);

	$self->method($self->method ? $self->method : 'GET');
	$self->connection_type($self->connection_type ? $self->connection_type : 'REGULAR');
	$self->SSL_connector($self->SSL_connector ? $self->SSL_connector : '');

	my $method = $self->method;
	my $command = $self->request_content || "";
	my $connection_type = $self->connection_type;

	my $host = $self->host_production;
	my $uri = $self->uri_production;

	# remove line returns from command
	$command =~ s/(\n|\r)//g if $command;

	my $command_response;

	# if the command needs to be sent over SSL
	if ($connection_type eq "SSL" and $self->SSL_connector ne 'HTTP::Request')
		{
		# use ssl function
		$command_response = $self->ssl_http_request($method, $host, $uri, $command);
		}
	else
		{
		# use regular httpd send function
		$command_response = $self->http_request($method, $host, $uri, $command);
		}

	#print STDERR "\n Response : " . $command_response;

	# set response, if any
	$self->response_content($command_response);

	#$self->log("COMMAND RESPONSE: $command_response");

	return $command_response;
	}

sub http_request
	{
	my $self = shift;
	my $method = shift; # GET or POST
	my $host = shift; # www.host.com
	my $uri = shift; #/xml.cgi....
	my $content = shift; # <XML>

	my $timeout = $self->timeout;

	my $UserAgent = LWP::UserAgent->new();
	my $HTTP_req;

	my $http_prefix = 'http://';

	if ($self->connection_type eq 'SSL')
		{
		$http_prefix = 'https://';
		}

	if ($method eq 'GET')
		{
		$uri .= IntelliShip::Utils->hex_string($content) if $uri and $content;
		$uri = '?' . $uri unless $uri =~ /^\?/;
		print STDERR "\n" . $http_prefix.$host.$uri;
		$HTTP_req = HTTP::Request->new(GET => $http_prefix . $host . $uri);
		}
	else
		{
		$HTTP_req = HTTP::Request->new(POST => $http_prefix . $host . $uri);

		if ($self->username and $self->password)
			{
			# authenticate
			$HTTP_req->authorization_basic($self->username, $self->password);
			}

		if ($self->content_type and length $self->content_type > 1)
			{
			$HTTP_req->content_type($self->content_type);
			}
		else
			{
			$HTTP_req->content_type('application/x-www-form-urlencoded');
			}

		$HTTP_req->content($content);
		$HTTP_req->content_length(length($content));
		}

	my $response_content;

	eval
		{
		# Define subroutine to run if alarm timeout occurs
		local $SIG{ALRM} = sub { die "alarm\n"; };

		# Set alarm to wake up in $timeout seconds...
		alarm $timeout;

		my $host_response = $UserAgent->request($HTTP_req);

		if ($host_response->is_success)
			{
			$response_content = $host_response->content();
			}
		else
			{
			$self->add_error('Request to host failed. ' . $host_response->content);
			alarm 0;
			return undef;
			}

		alarm 0;
		};

	if ($@)
		{
		$self->add_error('Host connection timeout, Timeout after $timeout seconds: ' . $@);
		return undef;
		}

	return $response_content;
	}

sub ssl_http_request
	{
	my $self = shift;
	my $method = shift;		# GET or POST
	my $host = shift; 		# www.host.com
	my $uri = shift; 		# /xml.cgi....
	my $content = shift; 	# <XML>

	my $timeout = $self->timeout;

	$self->content_type('text/xml') unless ($self->content_type);

	# use an eval statement to bring in the SSLeay class because
	# Apache won't start without it
	eval "use Net::SSLeay qw(get_https post_https sslcat make_headers make_form);";

	my ($page, $response, %reply_headers);

	$uri = "" unless $uri;

	eval
		{
		# Define subroutine to run if alarm timeout occurs
		local $SIG{ALRM} = sub { die "alarm\n"; };

		# Set alarm to wake up in $timeout seconds...
		alarm $timeout;

		# look at the type of method to determine function to use
		if ($method eq "POST")
			{
			# use POST function
			($page, $response, %reply_headers) = post_https(
				$host,
				443,
				$uri,
				make_headers('Content-Type' => $self->content_type),
				$content,
				);
			}
		else
			{
			# use GET function
			$uri .= IntelliShip::Utils->hex_string($content) if $uri and $content; # format content
			($page, $response, %reply_headers) = get_https($host, 443, $uri);
			}

		# we must receive a status of 200 from the server
		if ($response !~ /200 OK/i)
			{
			$self->add_error('Response from host was not properly formatted, ' . $response);

			alarm 0;
			return undef;
			}

		alarm 0;
		};

	# if the timeout was exceeded
	if ($@)
		{
		$self->add_error("Timeout after $timeout seconds: $@");
		return undef;
		}

	return $page;
	}

sub is_valid
	{
	my $self = shift;

	if (!$self->timeout)
		{
		$self->add_error('No timeout has been set');
		}
	if (!$self->method)
		{
		$self->add_error('No method has been set. Please choose between GET or POST');
		}
	if (!$self->request_content and $self->method eq 'POST')
		{
		$self->add_error('No request content has been set.');
		}
	if (!$self->host_production)
		{
		$self->add_error('No production host has been set. Please specify one in the format www.host.com');
		}
	if (!$self->uri_production)
		{
		$self->add_error('No production URI has been set.');
		}

	if ($self->has_errors)
		{
		print STDERR "\n Errors: " , @{$self->errors} , "\n";
		return undef;
		}

	return 1;
	}

__PACKAGE__->meta()->make_immutable();

no Mouse;

1;

__END__

=head1 NAME

IntelliShip::HTTP

=head1 SYNOPSIS

Easily access HTTP services, either via standard HTTP or HTTPS. Supports GET and POST methods.

GET Example:

	my $HTTP = IntelliShip::HTTP->new;
	$HTTP->method('GET');
	$HTTP->host_production('localhost');
	$HTTP->uri_production('/perl/xml/gateway.cgi');
	$HTTP->timeout('15');
	my $result = $HTTP->send;

POST Example:

	my $HTTP = IntelliShip::HTTP->new;
	$HTTP->method('POST');
	$HTTP->host_production('localhost');
	$HTTP->connection_type('SSL');
	$HTTP->uri_production('/perl/xml/gateway.cgi');
	$HTTP->request_content('content here');
	$HTTP->timeout('15');
	my $result = $HTTP->send;

GET Example using HTTPS:

	my $HTTP = IntelliShip::HTTP->new;
	$HTTP->method('GET');
	$HTTP->host_production('localhost');
	$HTTP->connection_type('SSL');
	$HTTP->uri_production('/perl/xml/gateway.cgi');
	$HTTP->timeout('15');
	my $result = $HTTP->send;

GET Example using HTTPS and HTTP::Request as the SSL connector module:

	my $HTTP = IntelliShip::HTTP->new;
	$HTTP->method('GET');
	$HTTP->host_production('localhost');
	$HTTP->connection_type('SSL');
	$HTTP->SSL_connector('HTTP::Request');
	$HTTP->uri_production('/perl/xml/gateway.cgi');
	$HTTP->timeout('15');
	my $result = $HTTP->send;

=head1 METHODS

=head2 new

get a new HTTP object

	my $HTTP = IntelliShip::HTTP->new;

=head2 method

can get either GET or POST.

	$HTTP->method('POST');

=head2 request_content

set the query string content for POST request

	$HTTP->request_content('myvar=XXXX&myvar2=XXXX');

=head2 connection_type

set the connection type to SSL, if needed.

	$HTTP->connection_type('SSL');

=head2 SSL_connector

if needed, use HTTP::Request as the SSL connector module instead of Net::SSLeay

	$HTTP->SSL_connector('HTTP::Request');

=head2 host_production

will use this host when operating in PRODUCTION mode.

	$HTTP->host_production('prod.myhost.com');

=head2 uri_production

will use this uri when operating in PRODUCTION mode.

	$HTTP->uri_production('/production.cgi');

=head2 timeout

set the timeout in seconds

	$HTTP->timeout($seconds);

=head2 send

send the HTTP request and get the response

	my $result = $HTTP->send;

=head2 is_valid

is the setup of HTTP object valid

	my $boolean = $HTTP->is_valid.

=cut