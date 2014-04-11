use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::BatchShipping;

ok( request('/customer/batchshipping')->is_success, 'Request should succeed' );
done_testing();
