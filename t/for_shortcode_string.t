use strict;
use warnings;

use Test::More;

use Finance::TradingStrategy::BuyAndHold;

my $strategy = new_ok('Finance::TradingStrategy' => [
    strategy => 'buy_and_hold',
]);
is($strategy->execute(quote => 1, buy_price => 2, value => 6), 1, 'this would buy');

done_testing;


