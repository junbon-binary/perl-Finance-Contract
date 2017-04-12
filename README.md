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
    # Show the current prices (as of now, since an explicit pricing date is not provided)
    say "Bid for CALLE:  " . $contract->bid_price;
    say "Ask for CALLE:  " . $contract->ask_price;
    # Get the contract with the opposite bet type, in this case a PUT
    my $opposite = $contract->opposite_contract;
    say "Bid for PUT:    " . $opposite->bid_price;
    say "Ask for PUT:    " . $opposite->ask_price;

# DESCRIPTION

This is a generic abstraction for financial stock market contracts.

# ATTRIBUTES - Construction

These are the parameters we expect to be passed when constructing a new contract.

## currency

The currency in which this contract is bought/sold, e.g. `USD`.

## payout

Payout amount value, see ["currency"](#currency).

## shortcode

(optional) This can be provided when creating a contract from a shortcode. If not, it will
be populated from the contract parameters.

## underlying\_symbol

The underlying asset, as a string (for example, ` frxUSDJPY `).

# ATTRIBUTES - Date-related

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

# ATTRIBUTES - Tick-expiry contracts

These are only valid for tick contracts.

## tick\_expiry

A boolean that indicates if a contract expires after a pre-specified number of ticks.

## prediction

Prediction (for tick trades) is what client predicted would happen.

## tick\_count

Number of ticks in this trade.

# ATTRIBUTES - Other

## starts\_as\_forward\_starting

This attribute tells us if this contract was initially bought as a forward starting contract.
This should not be mistaken for is\_forwarding\_start attribute as that could change over time.

# ATTRIBUTES - From contract\_types.yml

## id

## pricing\_code

## display\_name

## sentiment

## other\_side\_code

## payout\_type

## payouttime

# METHODS - Boolean checks

## is\_atm\_bet

Is this contract meant to be ATM or non ATM at start?
The status will not change throughout the lifetime of the contract due to differences in offerings for ATM and non ATM contracts.

# METHODS - Time-related

## timeinyears

Contract duration in years.

## timeindays

Contract duration in days.

# METHODS - Other

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
