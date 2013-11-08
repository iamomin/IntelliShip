use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::Order::New;

ok( request('/customer/order/new')->is_success, 'Request should succeed' );
done_testing();
