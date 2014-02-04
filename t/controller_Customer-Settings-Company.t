use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::Settings::Company;

ok( request('/customer/settings/company')->is_success, 'Request should succeed' );
done_testing();
