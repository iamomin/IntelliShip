use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::Report;

ok( request('/customer/report')->is_success, 'Request should succeed' );
done_testing();
