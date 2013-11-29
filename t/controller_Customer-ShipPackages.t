use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::ShipPackages;

ok( request('/customer/shippackages')->is_success, 'Request should succeed' );
done_testing();
