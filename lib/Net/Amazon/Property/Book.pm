######################################################################
package Net::Amazon::Property::Book;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Property);

__PACKAGE__->make_accessor($_) for qw(title publisher binding isbn);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    my $self = $class->SUPER::new(%options);
    bless $self, $class; # Bless into this class

    if(exists $options{xmlref}) {
        $self->init_via_xmlref($options{xmlref});
    }

    return $self;
}

##################################################
sub init_via_xmlref {
##################################################
    my($self, $xmlref) = @_;

    $self->SUPER::init_via_xmlref($xmlref);

    $self->authors($xmlref->{Authors}->{Author});
    $self->title($xmlref->{ProductName});
    $self->publisher($xmlref->{Manufacturer});
    $self->binding($xmlref->{Media});
    $self->isbn($xmlref->{Isbn});
}

##################################################
sub author {
##################################################
    my($self, $nameref) = @_;

    # Only return the first author
    return ($self->authors($nameref))[0];
}

##################################################
sub authors {
##################################################
    my($self, $nameref) = @_;

    if(defined $nameref) {
        if(ref $nameref eq "ARRAY") {
            $self->{authors} = $nameref;
        } else {
            $self->{authors} = [$nameref];
        }
    }

       # Return a list
    return $self->{authors} ? @{$self->{authors}} : ();
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    return join('/', $self->authors) . ", " .
      '"' . $self->title . '"' . ", " .
      $self->year . ", " .
      $self->OurPrice . ", " .
      $self->Asin;
}

1;

__END__

=head1 NAME

Net::Amazon::Property::Book - Class for books on amazon.com

=head1 SYNOPSIS

  use Net::Amazon;

  # ...

  if($resp->is_success()) {
      for my $prop ($resp->properties) {
          print join("/", $prop->authors(), " ",
                $prop->title(), " ",
                $prop->publisher(), " ",
                $prop->year(), "\n";
  }

=head1 DESCRIPTION

C<Net::Amazon::Property::Book> is derived from 
C<Net::Amazon::Property> and on top of the all-purpose
methods the base class provides, it offers specialized accessors for
book parameters.

=head2 METHODS

=over 4

=item authors()

Returns a list of the book's authors. There's also a C<author()> method
which just returns the I<first> author.

=item publisher()

Returns the book's publishing company as a string.

=item title()

Returns the book's title as a string.

=item isbn()

Returns the book's ISBN number.

=item new(xmlref => $xmlref)

Initializes an object by passing a hash of hashes structure containing
the XML data returned from the service. Usually, this is just used by
C<Net::Amazon> internally to initialize objects for on backcoming
data.

=back

Check out L<Net::Amazon::Property> for all-purpose accessors, like
C<year>, C<OurPrice>, C<ListPrice>, etc.

=head1 SEE ALSO

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
