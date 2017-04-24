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

You can either construct [from a shortcode and currency](#new_from_shortcode):

    Finance::Contract->new_from_shortcode('CALL_frxUSDJPY_1491965798_1491965808_100000000_0', 'USD');

or from build parameters:

    Finance::Contract->new({
        underlying    => 'frxUSDJPY',
        contract_type => 'CALL',
        date_start    => $now,
        duration      => '5t',
        currency      => 'USD',
        payout        => 100,
        barrier       => 100,
    });

## Dates

All date-related parameters:

- ["date\_pricing"](#date_pricing)
- ["date\_expiry"](#date_expiry)
- ["date\_start"](#date_start)

are [Date::Utility](https://metacpan.org/pod/Date::Utility) instances. You can provide them as epoch values
or [Date::Utility](https://metacpan.org/pod/Date::Utility) objects.

## new\_from\_shortcode

Instantiates a new Finance::Contract from the given shortcode and currency.

# ATTRIBUTES

These are the parameters we expect to be passed when constructing a new contract.

## contract\_type

The type of this contract as an upper-case string.

Current types include:

- `CALL`
- `PUT`
- `CALLE`
- `EXPIRYRANGE`
- `EXPIRYMISS`
- `DIGITMATCH`
- `DIGITOVER`

## currency

The currency in which this contract is bought/sold, e.g. `USD`.

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

## payout

Payout amount value, see ["currency"](#currency). Optional - only applies to binaries.

## prediction

Prediction (for tick trades) is what client predicted would happen.

## starts\_as\_forward\_starting

This attribute tells us if this contract was initially bought as a forward starting contract.
This should not be mistaken for ["is\_forward\_starting"](#is_forward_starting) attribute as that could change over time.

## supplied\_barrier\_type

One of:

- `relative` - this is of the form `S10P` or `S-4P`, which would be 10 pips above the spot
or 4 pips below the spot.
- `absolute` - this is a number that can be compared directly with the spot, e.g. `103.45`.
- `difference` - a numerical difference from the spot, can be negative, e.g. `-0.035`.

## supplied\_high\_barrier

For a 2-barrier contract, this is the high barrier string. The meaning of these barrier values is controlled by ["supplied\_barrier\_type"](#supplied_barrier_type).

## supplied\_low\_barrier

For a 2-barrier contract, this is the low barrier string.

## supplied\_barrier

For a single-barrier contract, this is the barrier string.

## tick\_count

Number of ticks in this trade.

## underlying\_symbol

The underlying asset, as a string (for example, ` frxUSDJPY `).

# ATTRIBUTES - From contract\_types.yml

## id

A unique numeric ID.

## pricing\_code

Used to determine the pricing engine that should be used for this contract. Examples
include 'PUT' or 'CALL'.

## display\_name

This is a human-readable name for the contract type, brief description of what it does.

## sentiment

Indicates whether we are speculating on market rise or fall.

## other\_side\_code

Opposite type for this contract - PUT for CALL, etc.

## payout\_type

Either ` binary ` or ` non-binary `.

## payouttime

Indicates when the contract pays out. Can be ` end ` or ` hit `.

# ATTRIBUTES - From contract\_categories.yml

## allow\_forward\_starting

True if we allow forward starting for this contract type.

## barrier\_at\_start

Boolean which will false if we don't know what the barrier is at the start of the contract (Asian contracts).

## category\_code

The code for this category.

## is\_path\_dependent

True if this is a path-dependent contract.

## supported\_expiries

Which expiry durations we allow for this category. Values can be:

- intraday
- daily
- tick

## two\_barriers

True if the contract has two barriers.

# METHODS

## barrier\_category

Type of barriers we have for this contract, depends on the contract type.

Possible values are:

- `american` - barrier for American-style contract
- `asian` - Asian-style contract
- `euro_atm` - at-the-money European contract
- `euro_non_atm` - non-at-the-money European contract
- `non_financial` - digits

## effective\_start

- For backpricing, this is ["date\_start"](#date_start).
- For a forward-starting contract, this is ["date\_start"](#date_start).
- For all other states - i.e. active, non-expired contracts - this is ["date\_pricing"](#date_pricing).

## fixed\_expiry

A Boolean to determine if this bet has fixed or flexible expiries.

## get\_time\_to\_expiry

Returns a TimeInterval to expiry of the bet. For a forward start bet, it will NOT return the bet lifetime, but the time till the bet expires.

If you want to get the contract life time, use:

    $contract->get_time_to_expiry({from => $contract->date_start})

## is\_atm\_bet

Is this contract meant to be ATM or non ATM at start?
The status will not change throughout the lifetime of the contract due to differences in offerings for ATM and non ATM contracts.

## shortcode

This is a compact string representation of a [Finance::Contract](https://metacpan.org/pod/Finance::Contract) object. It includes all data needed to
reconstruct a contract, with the exception of ["currency"](#currency).

## timeinyears

Contract duration in years.

## timeindays

Contract duration in days.

## ticks\_to\_expiry

Number of ticks until expiry of this contract. Defaults to one more than tick\_count,
TODO JB - this is overridden in the digit/Asian contracts, any idea why?
