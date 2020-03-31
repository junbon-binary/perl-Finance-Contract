package Finance::Contract::Category;

=head1 NAME

Finance::Contract::Category

=head1 SYNOPSYS

    my $contract_category = Finance::Contract::Category->new("callput");

=head1 DESCRIPTION

This class represents available contract categories.

=head1 ATTRIBUTES

=cut

use Moose;
use namespace::autoclean;
use File::ShareDir ();
use YAML qw(LoadFile);
use Format::Util::Numbers;

my $category_config = LoadFile(File::ShareDir::dist_file('Finance-Contract', 'contract_categories.yml'));

my $contract_type_config = LoadFile(File::ShareDir::dist_file('Finance-Contract', 'contract_types.yml'));

=head2 get_all_contract_types

Returns a list of all loaded contract types

=cut

sub get_all_contract_types {
    return $contract_type_config;
}

=head2 get_all_barrier_categories

Returns a list of all available barrier categories

=cut

sub get_all_barrier_categories {
    return qw(euro_atm euro_non_atm lookback american non_financial asian reset);
}

=head2 get_all_contract_categories

Returns a list of all loaded contract categories

=cut

sub get_all_contract_categories {
    return $category_config;
}

has code => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 code

Our internal code (callput, touchnotouch, ...)

=head2 display_name

What is the name of this bet as an action?

=head2 display_order

In which order should these be preferred for display in a UI?

=head2 explanation

How do we explain this contract category to a client?

=cut

has [qw(display_name display_order explanation supported_expiries)] => (
    is => 'ro',
);

has [qw(allow_forward_starting two_barriers)] => (
    is      => 'ro',
    default => 0,
);

has available_types => (
    is      => 'ro',
    default => sub { [] },
);

has offer => (
    is      => 'ro',
    default => 1,
);

has is_path_dependent => (
    is      => 'ro',
    default => 0,
);

has is_binary => (
    is      => 'ro',
    default => 1,
);

=head2 has_user_defined_expiry

Does this contract expect user defined expiry at start? Returns boolean.

=head2 has_financial_barrier

Does this contract expect a financial barrier? Returns boolean.

=head2 supported_amount_type

Returns the supported amount type of this contract.

=head2 allow_atm_barrier

Some path dependent contract starts as ATM

=head2 has_minimum_multiplier

Does this contract have a minimum multiplier restriction in place? Returns boolean.

=cut

has has_user_defined_expiry => (
    is      => 'ro',
    default => 1,
);

has has_financial_barrier => (
    is      => 'ro',
    default => 1,
);

has supported_amount_type => (
    is      => 'ro',
    default => sub { ['payout', 'stake'] },
);

has allow_atm_barrier => (
    is      => 'ro',
    default => 0,
);

has has_minimum_multiplier => (
    is      => 'ro',
    default => 0,
);

=head1 METHODS

=head2 barrier_at_start

When is the barrier determined, at the start of the contract or after contract expiry.

=cut

has barrier_at_start => (
    is      => 'ro',
    default => 1,
);

=head2 require_basis

A boolean that determines if a contract category requires basis as input.

=head2 require_multiplier

A boolean that determines if a contract category requires multiplier as input.

=head2 allowed_update

An array reference that contains the updatable attributes of a contract category.

=cut

has require_basis => (
    is      => 'ro',
    default => 1,
);

has require_multiplier => (
    is      => 'ro',
    default => 0,
);

has allowed_update => (
    is      => 'ro',
    default => sub { [] },
);

has custom_minimum_stake => (
    is      => 'ro',
    default => sub { {} },
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    die 'Cannot build Finance::Contract::Category without code'
        unless $_[0];

    my %args   = ref $_[0] eq 'HASH' ? %{$_[0]} : (code => $_[0]);
    my $config = $category_config;
    my $wanted = $config->{$args{code}};

    return $class->$orig(%args) unless $wanted;
    return $class->$orig(%args, %$wanted);
};

__PACKAGE__->meta->make_immutable;

1;

=head1 AUTHOR

RMG Tech (Malaysia) Sdn Bhd

=head1 LICENSE AND COPYRIGHT

Copyright 2013- RMG Technology (M) Sdn Bhd

=cut

