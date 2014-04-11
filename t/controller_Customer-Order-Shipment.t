use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::Order::Shipment;

ok( request('/customer/order/shipment')->is_success, 'Request should succeed' );
done_testing();
