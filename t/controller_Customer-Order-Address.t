use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::Order::Address;

ok( request('/customer/order/address')->is_success, 'Request should succeed' );
done_testing();
