use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::MyOrders;

ok( request('/customer/myorders')->is_success, 'Request should succeed' );
done_testing();
