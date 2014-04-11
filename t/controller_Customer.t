use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer;

ok( request('/customer')->is_success, 'Request should succeed' );
done_testing();
