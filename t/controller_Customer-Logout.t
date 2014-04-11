use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::Logout;

ok( request('/customer/logout')->is_success, 'Request should succeed' );
done_testing();
