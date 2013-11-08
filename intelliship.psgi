use strict;
use warnings;

use IntelliShip;

my $app = IntelliShip->apply_default_middlewares(IntelliShip->psgi_app);
$app;

