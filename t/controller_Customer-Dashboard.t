use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::Dashboard;

ok( request('/customer/dashboard')->is_success, 'Request should succeed' );
done_testing();
