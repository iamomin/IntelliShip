use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::Order::Multipage;

ok( request('/customer/order/multipage')->is_success, 'Request should succeed' );
done_testing();
