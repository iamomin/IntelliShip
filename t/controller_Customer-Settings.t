use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::Settings;

ok( request('/customer/settings')->is_success, 'Request should succeed' );
done_testing();
