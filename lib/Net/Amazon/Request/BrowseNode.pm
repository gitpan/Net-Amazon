######################################################################
package Net::Amazon::Request::BrowseNode;
######################################################################
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    if(exists $options{browsenode}) {
        if ($options{browsenode} =~ /^\d+$/) {
           $options{BrowseNodeSearch} = $options{browsenode};
           delete $options{browsenode};
        } else {
           die "Browse Node ID must be numeric.";
        }
    } else {
        die "Mandatory parameter 'browsenode' not defined";
    }

    if(!exists $options{mode}) {
        die "Mandatory parameter 'mode' not defined";
    }

    my $self = $class->SUPER::new(%options);

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::BrowseNode - request class for browse node search

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::BrowseNode;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::BrowseNode->new( 
      browsenode  => 30,
      mode     => 'books'
  );

  # Response is of type Net::Amazon::Response::BrowseNode
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::BrowseNode> is a class used to submit node search
requests to the Amazon web service.

The node to search for is specified in the C<browsenode> parameter. The
browse node ID is a number that corresponds to a general subject area 
of Amazon.com.

To find browse node IDs, the best way is to visit the "browse" area 
of the various product lines at Amazon.com. When you find a subject area 
that you would like to generate XML for, look at the web page URL. The 
browse ID should appear after the string "/tg/browse/-/". Here are some 
examples of URLs that contain browse IDs:

=over 8

http://www.amazon.com/exec/obidos/tg/browse/-/30 
(In this example, the browse ID = 30)

http://www.amazon.com/exec/obidos/tg/browse/-/467970 
(In this example, the browse ID = 467970)

http://www.amazon.com/exec/obidos/tg/browse/-/602314 
(In this example, the browse ID = 60231

=back

Please be aware that some nodes cannot be used with a
BrowseNodeSearch. (The vast majority of them can, but you
may run across a few that simply will not work). It is also
important to point out that from time to time, some browse
nodes are deprecated or are changed without notice.

The catalog to search in is specified in the C<mode> parameter,
typical values are C<books>, C<music>, C<classical> or C<electronics>.

An optional C<keywords> parameter may be added to filter the results by that keyword.

Upon success, the responses' C<properties()> method will return a list of
C<Net::Amazon::Properties::*> objects.

=head2 METHODS

=over 4

=item new( browsenode => $nodeID, mode => $mode [, keywords => $keywords] )

Constructs a new C<Net::Amazon::Request::BrowseNode> object, used to query
the Amazon web service for items in a particular category (node) in the 
mode (catalog) specified.

=back

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head1 AUTHOR

Net::Amazon framework by Mike Schilli, E<lt>m@perlmeister.comE<gt>

BrowseNode.pm by Jackie Hamilton, E<lt>kira@cgi101.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut