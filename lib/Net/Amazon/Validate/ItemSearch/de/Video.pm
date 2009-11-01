# -*- perl -*-
# !!! DO NOT EDIT !!!
# This file was automatically generated.
package Net::Amazon::Validate::ItemSearch::de::Video;

use 5.006;
use strict;
use warnings;

sub new {
    my ($class , %options) = @_;
    my $self = {
        '_default' => 'Title',
        %options,
    };

    push @{$self->{_options}}, 'Actor';
    push @{$self->{_options}}, 'AudienceRating';
    push @{$self->{_options}}, 'Availability';
    push @{$self->{_options}}, 'BrowseNode';
    push @{$self->{_options}}, 'BrowseNode';
    push @{$self->{_options}}, 'Condition';
    push @{$self->{_options}}, 'Count';
    push @{$self->{_options}}, 'Director';
    push @{$self->{_options}}, 'Format';
    push @{$self->{_options}}, 'ItemPage';
    push @{$self->{_options}}, 'ItemPage';
    push @{$self->{_options}}, 'Keywords';
    push @{$self->{_options}}, 'Keywords';
    push @{$self->{_options}}, 'MPAARating';
    push @{$self->{_options}}, 'Magazines';
    push @{$self->{_options}}, 'Manufacturer';
    push @{$self->{_options}}, 'MaximumPrice';
    push @{$self->{_options}}, 'MerchantId';
    push @{$self->{_options}}, 'MinimumPrice';
    push @{$self->{_options}}, 'Performer';
    push @{$self->{_options}}, 'PostalCode';
    push @{$self->{_options}}, 'Publisher';
    push @{$self->{_options}}, 'Sort';
    push @{$self->{_options}}, 'Sort';
    push @{$self->{_options}}, 'State';
    push @{$self->{_options}}, 'Title';
    push @{$self->{_options}}, 'Title';

    bless $self, $class;
}

sub user_or_default {
    my ($self, $user) = @_;
    if (defined $user && length($user) > 0) {    
        return $self->find_match($user);
    } 
    return $self->default();
}

sub default {
    my ($self) = @_;
    return $self->{_default};
}

sub find_match {
    my ($self, $value) = @_;
    for (@{$self->{_options}}) {
        return $_ if lc($_) eq lc($value);
    }
    die "$value is not a valid value for de::Video!\n";
}

1;

__END__

=head1 NAME

Net::Amazon::Validate::ItemSearch::de::Video - valid search indicies
for the de locale and the Video SearchIndex.

=head1 DESCRIPTION

The default value is Title, unless mode is specified.

The list of available values are:

    Actor
    AudienceRating
    Availability
    BrowseNode
    BrowseNode
    Condition
    Count
    Director
    Format
    ItemPage
    ItemPage
    Keywords
    Keywords
    MPAARating
    Magazines
    Manufacturer
    MaximumPrice
    MerchantId
    MinimumPrice
    Performer
    PostalCode
    Publisher
    Sort
    Sort
    State
    Title
    Title

=cut
