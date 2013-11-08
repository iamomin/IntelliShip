use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::Order::Ajax;

ok( request('/customer/order/ajax')->is_success, 'Request should succeed' );
done_testing();
