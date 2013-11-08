use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::Order::Review;

ok( request('/customer/order/review')->is_success, 'Request should succeed' );
done_testing();
