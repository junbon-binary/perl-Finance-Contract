package Finance::Contract;

use strict;
use warnings;

=head1 NAME

Finance::Contract - represents a contract object for a single bet

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This is a generic abstraction for financial stock market contracts.

=cut

use Moose;

use Time::HiRes qw(time);
use List::Util qw(min max first);
use Scalar::Util qw(looks_like_number);
use Math::Util::CalculatedValue::Validatable;
use Date::Utility;
use Format::Util::Numbers qw(to_monetary_number_format roundnear);
use Time::Duration::Concise;

my $contract_type_config     = LoadFile(File::ShareDir::dist_file('LandingCompany', 'contract_types.yml'));

=head2 get_all_contract_types

Returns a list of all loaded contract types

=cut

sub get_all_contract_types {
    return $contract_type_config;
}



my @date_attribute = (
    isa        => 'date_object',
    lazy_build => 1,
    coerce     => 1,
);

=head1 ATTRIBUTES - Construction

These are the parameters we expect to be passed when constructing a new contract.

=cut

=head2 currency

The currency in which this contract is bought/sold, e.g. C<USD>.

=cut

has currency => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 payout

Payout amount value, see L</currency>.

=cut

has payout => (
    is         => 'ro',
    isa        => 'Num',
    lazy_build => 1,
);

=head2 shortcode

(optional) This can be provided when creating a contract from a shortcode. If not, it will
be populated from the contract parameters.

=cut

has shortcode => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

=head2 underlying_symbol

The underlying asset, as a string (for example, C< frxUSDJPY >).

=cut

has underlying_symbol => (
    is      => 'ro',
    isa     => 'Str',
);

=head1 ATTRIBUTES - Date-related

=cut

=head2 date_expiry

When the contract expires.

=cut

has date_expiry => (
    is => 'rw',
    @date_attribute,
);

=head2 date_pricing

The date at which we're pricing the contract. Provide C< undef > to indicate "now".

=cut

has date_pricing => (
    is => 'ro',
    @date_attribute,
);

=head2 date_start

For American contracts, defines when the contract starts.

For Europeans, this is used to determine the barrier when the requested barrier is relative.

=cut

has date_start => (
    is => 'ro',
    @date_attribute,
);

=head2 duration

The requested contract duration, specified as a string indicating value with units.
The unit is provided as a single character suffix:

=over 4

=item * t - ticks

=item * s - seconds

=item * m - minutes

=item * h - hours

=item * d - days

=back

Examples would be C< 5t > for 5 ticks, C< 3h > for 3 hours.

=cut

has duration => (is => 'ro');

=head1 ATTRIBUTES - Tick-expiry contracts

These are only valid for tick contracts.

=cut

=head2 tick_expiry

A boolean that indicates if a contract expires after a pre-specified number of ticks.

=cut

has tick_expiry => (
    is      => 'ro',
    default => 0,
);

=head2 prediction

Prediction (for tick trades) is what client predicted would happen.

=cut

has prediction => (
    is  => 'ro',
    isa => 'Maybe[Num]',
);

=head2 tick_count

Number of ticks in this trade.

=cut

has tick_count => (
    is  => 'ro',
    isa => 'Maybe[Num]',
);

=head1 ATTRIBUTES - Other

=cut

=head2 starts_as_forward_starting

This attribute tells us if this contract was initially bought as a forward starting contract.
This should not be mistaken for is_forwarding_start attribute as that could change over time.

=cut

has starts_as_forward_starting => (
    is      => 'ro',
    default => 0,
);

has is_forward_starting => (
    is         => 'ro',
    lazy_build => 1,
);

#fixed_expiry - A Boolean to determine if this bet has fixed or flexible expiries.

has fixed_expiry => (
    is      => 'ro',
    default => 0,
);

has remaining_time => (
    is         => 'ro',
    isa        => 'Time::Duration::Concise',
    lazy_build => 1,
);

has [qw(barrier_category)] => (
    is         => 'ro',
    lazy_build => 1,
);

# This is needed to determine if a contract is newly priced
# or it is repriced from an existing contract.
# Milliseconds matters since UI is reacting much faster now.
has _date_pricing_milliseconds => (
    is => 'rw',
);

=head1 ATTRIBUTES - From contract_types.yml

=head2 id

=head2 pricing_code

=head2 display_name

=head2 sentiment

=head2 other_side_code

=head2 payout_type

=head2 payouttime

=cut

has [qw(id pricing_code display_name sentiment other_side_code payout_type payouttime)] => (
    is      => 'ro',
    default => undef,
);

=head1 METHODS - Boolean checks

=cut

=head2 is_atm_bet

Is this contract meant to be ATM or non ATM at start?
The status will not change throughout the lifetime of the contract due to differences in offerings for ATM and non ATM contracts.

=cut

sub is_atm_bet {
    my $self = shift;

    return 0 if $self->two_barriers;
    # if not defined, it is non ATM
    return 0 if not defined $self->supplied_barrier;
    return 0 if $self->supplied_barrier ne 'S0P';
    return 1;
}

=head1 METHODS - Proxied to L<Finance::Contract::Category>

Our C<category> attribute provides several helper methods:

=cut

has category => (
    is      => 'ro',
    isa     => 'bom_contract_category',
    coerce  => 1,
    handles => [qw(supported_expiries is_path_dependent allow_forward_starting two_barriers barrier_at_start)],
);

=head2 supported_expiries

Which expiry durations we allow. Values can be:

=over 4

=item * intraday

=item * daily

=item * tick

=back

=cut

=head2 supported_start_types

(removed)

=cut

=head2 is_path_dependent

True if this is a path-dependent contract.

=cut

=head2 allow_forward_starting

True if we allow forward starting for this contract type.

=cut

=head2 two_barriers

True if the contract has two barriers.

=cut

=head2 barrier_at_start

The starting barrier value.

=cut

=head2 category_code

The code for this category.

=cut

sub category_code {
    my $self = shift;
    return $self->category->code;
}

=head1 METHODS - Time-related

=cut

=head2 timeinyears

Contract duration in years.

=head2 timeindays

Contract duration in days.

=cut

has [qw(
        timeinyears
        timeindays
        )
    ] => (
    is         => 'ro',
    init_arg   => undef,
    isa        => 'Math::Util::CalculatedValue::Validatable',
    lazy_build => 1,
    );

sub _build_timeinyears {
    my $self = shift;

    my $tiy = Math::Util::CalculatedValue::Validatable->new({
        name        => 'time_in_years',
        description => 'Bet duration in years',
        set_by      => 'Finance::Contract',
        base_amount => 0,
        minimum     => 0.000000001,
    });

    my $days_per_year = Math::Util::CalculatedValue::Validatable->new({
        name        => 'days_per_year',
        description => 'We use a 365 day year.',
        set_by      => 'Finance::Contract',
        base_amount => 365,
    });

    $tiy->include_adjustment('add',    $self->timeindays);
    $tiy->include_adjustment('divide', $days_per_year);

    return $tiy;
}

sub _build_timeindays {
    my $self = shift;

    my $atid = $self->get_time_to_expiry({
            from => $self->effective_start,
        })->days;

    my $tid = Math::Util::CalculatedValue::Validatable->new({
        name        => 'time_in_days',
        description => 'Duration of this bet in days',
        set_by      => 'Finance::Contract',
        minimum     => 0.000001,
        maximum     => 730,
        base_amount => $atid,
    });

    return $tid;
}

=head1 METHODS - Other

=cut

=head2 ticks_to_expiry

Number of ticks until expiry of this contract. Defaults to one more than tick_count,
TODO JB - this is overridden in the digit/Asian contracts, any idea why?

=cut

sub ticks_to_expiry {
    return shift->tick_count + 1;
}

=head2 effective_start

=over 4

=item * For backpricing, this is L</date_start>.

=item * For a forward-starting contract, this is L</date_start>.

=item * For all other states - i.e. active, non-expired contracts - this is L</date_pricing>.

=back

=cut

sub effective_start {
    my $self = shift;

    return
          ($self->date_pricing->is_after($self->date_expiry)) ? $self->date_start
        : ($self->date_pricing->is_after($self->date_start))  ? $self->date_pricing
        :                                                       $self->date_start;
}

=head2 get_time_to_expiry

Returns a TimeInterval to expiry of the bet. For a forward start bet, it will NOT return the bet lifetime, but the time till the bet expires.

If you want to get the contract life time, use:

    $contract->get_time_to_expiry({from => $contract->date_start})

=cut

sub get_time_to_expiry {
    my ($self, $attributes) = @_;

    $attributes->{'to'} = $self->date_expiry;

    return $self->_get_time_to_end($attributes);
}

# INTERNAL METHODS

# Send in the correct 'to'
sub _get_time_to_end {
    my ($self, $attributes) = @_;

    my $end_point = $attributes->{to};
    my $from = ($attributes and $attributes->{from}) ? $attributes->{from} : $self->date_pricing;

    # Don't worry about how long past expiry
    # Let it die if they gave us nonsense.

    return Time::Duration::Concise->new(
        interval => max(0, $end_point->epoch - $from->epoch),
    );
}

#== BUILDERS =====================

sub _build_date_pricing {
    return Date::Utility->new;
}

sub _build_is_forward_starting {
    my $self = shift;

    return ($self->allow_forward_starting and $self->date_pricing->is_before($self->date_start)) ? 1 : 0;
}

sub _build_remaining_time {
    my $self = shift;

    my $when = ($self->date_pricing->is_after($self->date_start)) ? $self->date_pricing : $self->date_start;

    return $self->get_time_to_expiry({
        from => $when,
    });
}

sub _build_shortcode {
    my $self = shift;

    my $shortcode_date_start = (
               $self->is_forward_starting
            or $self->starts_as_forward_starting
    ) ? $self->date_start->epoch . 'F' : $self->date_start->epoch;
    my $shortcode_date_expiry =
          ($self->tick_expiry)  ? $self->tick_count . 'T'
        : ($self->fixed_expiry) ? $self->date_expiry->epoch . 'F'
        :                         $self->date_expiry->epoch;

    my @shortcode_elements = ($self->code, $self->underlying->symbol, $self->payout, $shortcode_date_start, $shortcode_date_expiry);

    if ($self->two_barriers) {
        push @shortcode_elements, ($self->high_barrier->for_shortcode, $self->low_barrier->for_shortcode);
    } elsif ($self->barrier and $self->barrier_at_start) {
        # Having a hardcoded 0 for single barrier is dumb.
        # We should get rid of this legacy
        push @shortcode_elements, ($self->barrier->for_shortcode, 0);
    }

    return uc join '_', @shortcode_elements;
}

sub _build_date_start {
    return Date::Utility->new;
}

our $BARRIER_CATEGORIES = {
    callput      => ['euro_atm', 'euro_non_atm'],
    endsinout    => ['euro_non_atm'],
    touchnotouch => ['american'],
    staysinout   => ['american'],
    digits       => ['non_financial'],
    asian        => ['asian'],
    spreads      => ['spreads'],
};

sub _build_barrier_category {
    my $self = shift;

    my $barrier_category;
    if ($self->category->code eq 'callput') {
        $barrier_category = ($self->is_atm_bet) ? 'euro_atm' : 'euro_non_atm';
    } else {
        $barrier_category = $BARRIER_CATEGORIES->{$self->category->code}->[0];
    }

    return $barrier_category;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
