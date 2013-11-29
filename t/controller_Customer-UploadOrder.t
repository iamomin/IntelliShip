use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::UploadOrder;

ok( request('/customer/uploadorder')->is_success, 'Request should succeed' );
done_testing();
