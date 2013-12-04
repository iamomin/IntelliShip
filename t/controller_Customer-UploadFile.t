use strict;
use warnings;
use Test::More;


use Catalyst::Test 'IntelliShip';
use IntelliShip::Controller::Customer::UploadFile;

ok( request('/customer/uploadfile')->is_success, 'Request should succeed' );
done_testing();
