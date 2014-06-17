use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::SupplyOrdering;

ok( request('/customer/supplyordering')->is_success, 'Request should succeed' );
done_testing();
