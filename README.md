# NAME

Finance::Contract - represents a contract object for a single bet

# SYNOPSIS

    use feature qw(say);
    use Finance::Contract;
    # Create a simple contract
    my $contract = Finance::Contract->new(
        contract_type => 'CALLE',
        duration      => '5t',
    );

# DESCRIPTION

This is a generic abstraction for financial stock market contracts.

## Construction

You can either construct from a shortcode and currency:

    Finance::Contract->new('CALL_frxUSDJPY_1491965798_1491965808_100_0', 'USD');

or from build parameters:

    Finance::Contract->new({
        underlying   => 'frxUSDJPY',
        bet_type     => 'CALL',
        date_start   => $now,
        duration     => '5t',
        currency     => 'USD',
        payout       => 100,
        barrier      => 100,
    });

## Dates

All date-related parameters:

- ["date\_pricing"](#date_pricing)
- ["date\_expiry"](#date_expiry)
- ["date\_start"](#date_start)

are [Date::Utility](https://metacpan.org/pod/Date::Utility) instances. You can provide them as epoch values
or [Date::Utility](https://metacpan.org/pod/Date::Utility) objects.

# ATTRIBUTES

These are the parameters we expect to be passed when constructing a new contract.

## currency

The currency in which this contract is bought/sold, e.g. `USD`.

## payout

Payout amount value, see ["currency"](#currency). Optional - only applies to binaries.

## shortcode

(optional) This can be provided when creating a contract from a shortcode. If not, it will
be populated from the contract parameters.

## underlying\_symbol

The underlying asset, as a string (for example, ` frxUSDJPY `).

## date\_expiry

When the contract expires.

## date\_pricing

The date at which we're pricing the contract. Provide ` undef ` to indicate "now".

## date\_start

For American contracts, defines when the contract starts.

For Europeans, this is used to determine the barrier when the requested barrier is relative.

## duration

The requested contract duration, specified as a string indicating value with units.
The unit is provided as a single character suffix:

- t - ticks
- s - seconds
- m - minutes
- h - hours
- d - days

Examples would be ` 5t ` for 5 ticks, ` 3h ` for 3 hours.

## prediction

Prediction (for tick trades) is what client predicted would happen.

## tick\_count

Number of ticks in this trade.

## starts\_as\_forward\_starting

This attribute tells us if this contract was initially bought as a forward starting contract.
This should not be mistaken for ["is\_forward\_starting"](#is_forward_starting) attribute as that could change over time.

## supplied\_barrier\_type

Either 'relative' or 'absolute'. Relative barriers need market data in order to be calculated.

## supplied\_high\_barrier

For a 2-barrier contract, this is the high barrier string.

## supplied\_low\_barrier

For a 2-barrier contract, this is the low barrier string.

## supplied\_barrier

For a single-barrier contract, this is the barrier string.

# ATTRIBUTES - From contract\_types.yml

## id

## pricing\_code

## display\_name

## sentiment

## other\_side\_code

## payout\_type

## payouttime

# METHODS

## is\_atm\_bet

Is this contract meant to be ATM or non ATM at start?
The status will not change throughout the lifetime of the contract due to differences in offerings for ATM and non ATM contracts.

## supported\_expiries

Which expiry durations we allow. Values can be:

- intraday
- daily
- tick

## is\_path\_dependent

True if this is a path-dependent contract.

## allow\_forward\_starting

True if we allow forward starting for this contract type.

## two\_barriers

True if the contract has two barriers.

## barrier\_at\_start

Boolean which will false if we don't know what the barrier is at the start of the contract (Asian contracts).

## category\_code

The code for this category.

## timeinyears

Contract duration in years.

## timeindays

Contract duration in days.

## ticks\_to\_expiry

Number of ticks until expiry of this contract. Defaults to one more than tick\_count,
TODO JB - this is overridden in the digit/Asian contracts, any idea why?

## effective\_start

- For backpricing, this is ["date\_start"](#date_start).
- For a forward-starting contract, this is ["date\_start"](#date_start).
- For all other states - i.e. active, non-expired contracts - this is ["date\_pricing"](#date_pricing).

## get\_time\_to\_expiry

Returns a TimeInterval to expiry of the bet. For a forward start bet, it will NOT return the bet lifetime, but the time till the bet expires.

If you want to get the contract life time, use:

    $contract->get_time_to_expiry({from => $contract->date_start})

## \_shortcode\_to\_parameters

Convert a shortcode and currency pair into parameters suitable for creating a Finance::Contract
