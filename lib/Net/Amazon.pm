######################################################################
package Net::Amazon;
######################################################################
# Mike Schilli <m@perlmeister.com>, 2003
######################################################################

use 5.006;
use strict;
use warnings;

our $VERSION          = '0.07';
our $AMZN_XML_URL     = "http://xml.amazon.com/onca/xml2";
our @CANNED_RESPONSES = ();

use LWP::UserAgent;
use HTTP::Request::Common;
use XML::Simple;
use Data::Dumper;
use URI;
use Log::Log4perl qw(:easy);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    if(! exists $options{token}) {
        die "Mandatory paramter 'token' not defined";
    }

    if(! exists $options{affiliate_id}) {
        $options{affiliate_id} = "webservices-20";
    }

    my $self = {
        max_pages => 5,
        %options,
               };

    bless $self, $class;
}

##################################################
sub request {
##################################################
    my($self, $request) = @_;

    my $AMZN_WISHLIST_BUG_ENCOUNTERED = 0;

    my $resp_class = $request->response_class();

    eval "require $resp_class;" or 
        die "Cannot find '$resp_class'";

    my $res  = $resp_class->new();

    my $url  = URI->new($AMZN_XML_URL);
    my $page = 0;
    my $ref;

    {
        $page++;

        my %params = $request->params();
        $params{page}   = $page;
        $params{locale} = $self->{locale} if exists $self->{locale};

        $url->query_form(
            'dev-t' => $self->{token},
            't'     => $self->{affiliate_id},
            %params,
        );

        my $urlstr = $url->as_string;
        my $xml = fetch_url($urlstr, $res);

        if(!defined $xml) {
            return $res;
        }

        DEBUG(sub { "Received [ " . $xml . "]" });

        my $xs = XML::Simple->new();
        $ref = $xs->XMLin($xml);

        # DEBUG(sub { Data::Dumper::Dumper($ref) });

        if(! defined $ref) {
            ERROR("Invalid XML");
            $res->message("Invalid XML");
            $res->status("");
            return $res;
        }

        if(exists $ref->{TotalPages}) {
            INFO("Page $page/$ref->{TotalPages}");
        }

        if(exists $ref->{ErrorMsg}) {

            if($AMZN_WISHLIST_BUG_ENCOUNTERED &&
               $ref->{ErrorMsg} =~ /no exact matches/) {
                DEBUG("End of buggy wishlist detected");
                last;
            }
                
            ERROR("Fetch Error: $ref->{ErrorMsg}");
            $res->message("$ref->{ErrorMsg}");
            $res->status("");
            return $res;
        }

        my $new_items = $res->xmlref_add($ref);
        DEBUG("Received valid XML ($new_items items)");

        # Stop if we've fetched max_pages already
        if($self->{max_pages} <= $page) {
            DEBUG("Fetched max_pages ($self->{max_pages}) -- stopping");
            last;
        }

        # Work around the Amazon bug not setting TotalPages properly
        # for wishlists
        if(ref($res) =~ /Wishlist/ and
           !exists $ref->{TotalPages}  and
           $new_items == 10
          ) {
            $AMZN_WISHLIST_BUG_ENCOUNTERED = 1;
            DEBUG("Trying to fetch additional wishlist page (AMZN bug)");
            redo;
        }

        if(exists $ref->{TotalPages} and
           $ref->{TotalPages} > $page) {
            DEBUG("Page $page of $ref->{TotalPages} fetched - continuing");
            redo;
        }

        # We're gonna fall out of this loop here.
    }

    $res->status(1);
    return $res;
}

##################################################
sub fetch_url {
##################################################
    my($url, $res) = @_;

    my $max_retries = 2;

    INFO("Fetching $url");

    if(@CANNED_RESPONSES) {
        INFO("Serving canned response (testing)");
        return shift @CANNED_RESPONSES;
    }

    my $ua = LWP::UserAgent->new();
    my $resp;

    {
        $resp = $ua->request(GET $url);

        if($resp->is_error) {
            $res->status("");
            $res->message($resp->message);
            return undef;
        }

        if($resp->content =~ /<ErrorMsg>/ &&
           $resp->content =~ /Please retry/i) {
            if($max_retries-- >= 0) {
                INFO("Temporary Amazon error, retrying");
                sleep(1);
                redo;
            } else {
                INFO("Out of retries, giving up");
                $res->status("");
                $res->message("Too many temporary Amazon errrors");
                return undef;
            }
        }
    }

    return $resp->content();
}

##################################################
# Poor man's Class::Struct
##################################################
sub make_accessor {
##################################################
    my($package, $name) = @_;

    no strict qw(refs);

    my $code = <<EOT;
        *{"$package\\::$name"} = sub {
            my(\$self, \$value) = \@_;

            if(defined \$value) {
                \$self->{$name} = \$value;
            }
            if(exists \$self->{$name}) {
                return (\$self->{$name});
            } else {
                return "";
            }
        }
EOT
    if(! defined *{"$package\::$name"}) {
        eval $code or die "$@";
    }
}

##################################################
sub xmlref_add {
##################################################
    my($self, $xmlref) = @_;

    my $nof_items_added = 0;

    # Push a nested hash structure, retrieved via XMLSimple, onto the
    # object's internal 'xmlref' entry, which holds a ref to an array, 
    # whichs elements are refs to hashes holding an item's attributes
    # (like OurPrice etc.)

    #DEBUG("xmlref_add ", Data::Dumper::Dumper($xmlref));

    unless(ref($self->{xmlref}) eq "HASH" &&
           ref($self->{xmlref}->{Details}) eq "ARRAY") {
        $self->{xmlref}->{Details} = [];
    }

    if(ref($xmlref->{Details}) eq "ARRAY") {
        # Is it an array of items?
        push @{$self->{xmlref}->{Details}}, @{$xmlref->{Details}};
        $nof_items_added = scalar @{$xmlref->{Details}};
    } else {
        # It is a single item
        push @{$self->{xmlref}->{Details}}, $xmlref->{Details};
        $nof_items_added = 1;
    }

    #DEBUG("xmlref_add (after):", Data::Dumper::Dumper($self));
    return $nof_items_added;
}

1;

__END__

=head1 NAME

Net::Amazon - Framework for accessing amazon.com via SOAP and XML/HTTP

=head1 SYNOPSIS

  use Net::Amazon;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::ASIN->new( 
      asin  => '0201360683'
  );

    # Response is of type Net::Amazon::Response::ASIN
  my $resp = $ua->request($req);

  if($resp->is_success()) {
      print $resp->as_string();
  } else {
      print "Error: ", $resp->message(), "\n";
  }

=head1 ABSTRACT

  Net::Amazon provides an object-oriented interface to amazon.com's
  SOAP and XML/HTTP interfaces. This way it's possible to create applications
  using Amazon's vast amount of data via a functional interface, without
  having to worry about the underlying communication mechanism.

=head1 DESCRIPTION

C<Net::Amazon> works very much like C<LWP>: First you define a useragent
like

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN',
      max_pages   => 3,
  );

which you pass your personal amazon developer's token (can be obtained
from http://amazon.com/soap) and (optionally) the maximum number of 
result pages the agent is going to request from Amazon in case all
results don't fit on a single page (typically holding 20 items).

According to the different search methods on Amazon, there's a bunch
of different request objects in C<Net::Amazon>:

=over 4

=item Net::Amazon::Request::ASIN

Search by ASIN, mandatory parameter C<asin>. 
Returns at most one result.

=item Net::Amazon::Request::Artist

Music search by Artist, mandatory parameter C<artist>.
Can return many results.

=item Net::Amazon::Request::Keyword

Music search by Artist, mandatory parameters C<keyword> and C<mode>.
Can return many results.

=item Net::Amazon::Request::UPC

Music search by UPC (product barcode), mandatory parameter C<upc>.
C<mode> has to be set to C<music>. Returns at most one result.

=back

Check the respective man pages for details on these request objects
(However, they haven't been written yet, so check later :).
Request objects are typically created like this (with a Keyword query
as an example):

    my $req = Net::Amazon::Request::Keyword->new(
        keyword   => 'perl',
        mode      => 'books',
    );

and are handed over to the user agent like that:

    # Response is of type Net::Amazon::Response::ASIN
  my $resp = $ua->request($req);

  if($resp->is_success()) {
      print $resp->as_string();
  } else {
      print "Error: ", $resp->message(), "\n";
  }

The user agent returns a response object, containing one or more
Amazon 'properties', as it calls the products found.
All matches can be retrieved from the Response 
object using it's C<properties()> method.

Response objects always have the methods 
C<is_success()>,
C<is_error()>,
C<message()>,
C<as_string()> and
C<properties()> available.

C<properties()> returns one or more C<Net::Amazon::Property> objects of type
C<Net::Amazon::Property> (or one of its subclasses like
C<Net::Amazon::Property::Book>, C<Net::Amazon::Property::Music>
or Net::Amazon::Property::DVD), each
of which features accessors named after the attributes of the product found
in Amazon's database:

    for ($resp->properties) {
       print $_->Asin(), " ",
             $_->OurPrice(), "\n";
    }

Also the specialized classes C<Net::Amazon::Property::Book> and
C<Net::Amazon::Property::Music> feature convenience methods like
C<authors()> (returning the list of authors of a book) or 
C<album()> for CDs, returning the album title.

=head2 METHODS

=over 4

=item $ua = Net::Amazon->new(token => $token, ...)

Create a new Net::Amazon useragent. C<$token> is the value of 
the mandatory Amazon developer's token, which can be obtained from
http://amazon.com/soap. 

Additional optional parameters:

=over 4

=item max_pages =E<gt> $max_pages

sets how many 
result pages the module is supposed to fetch back from Amazon, which
only sends back 10 results per page. 

=item affiliate_id =E<gt> $affiliate_id

your Amazon affiliate ID, if you have one. It defaults to 
C<webservices-20> which is currently (as of 05/2003) 
required by Amazon.

=back

=item $resp = $ua->request($request)

Sends a request to the Amazon web service. C<$request> is of a 
C<Net::Amazon::Request::*> type and C<$response> will be of the 
corresponding C<Net::Amazon::Response::*> type.

=back

=head2 Accessing foreign Amazon Catalogs

As of this writing (June 2003), Amazon also offers its web service for
its UK catalog. Just pass

    locale => 'uk'

to C<Net::Amazon>'s constructor C<new()> and instead of returning
results sent by the US mothership, it will query the UK catalog
and show prices in (gack!) Pounds.

=head2 EXAMPLE

Here's a full-fledged example doing a artist search:

    use Net::Amazon;
    use Net::Amazon::Request::Artist;
    use Data::Dumper;

    die "usage: $0 artist\n(use Zwan as an example)\n" 
        unless defined $ARGV[0];

    my $ua = Net::Amazon->new(
        token       => 'YOUR_AMZN_TOKEN',
    );

    my $req = Net::Amazon::Request::Artist->new(
        artist  => $ARGV[0],
    );

       # Response is of type Net::Amazon::Artist::Response
    my $resp = $ua->request($req);

    print $resp->as_string, "\n";

And here's one displaying someone's wishlist:

    use Net::Amazon;
    use Net::Amazon::Request::Wishlist;
    
    die "usage: $0 wishlist_id\n" .
        "(use 1XL5DWOUFMFVJ as an example)\n" unless $ARGV[0];

    my $ua = Net::Amazon->new(
        token       => 'YOUR_AMZN_TOKEN',
    );

    my $req = Net::Amazon::Request::Wishlist->new(
        id  => $ARGV[0]
    );

       # Response is of type Net::Amazon::ASIN::Response
    my $resp = $ua->request($req);
    
    print $resp->as_string, "\n";

=head1 DEBUGGING

If something's going wrong and you want more verbosity, just bump up
C<Net::Amazon>'s logging level. C<Net::Amazon> comes with C<Log::Log4perl>
statements embedded, which are disabled by default. However, if you initialize 
C<Log::Log4perl>, e.g. like

    use Net::Amazon;
    use Log::Log4perl qw(:easy);

    Log::Log4perl->easy_init($DEBUG);
    my Net::Amazon->new();
    # ...

you'll see what's going on behind the scenes, what URLs the module 
is requesting from Amazon and so forth.

=head1 INSTALLATION

C<Net::Amazon> depends on Log::Log4perl, which can be pulled from CPAN by
simply saying

    perl -MCPAN -eshell 'install Log::Log4perl'

Then, C<Net::Amazon> installs with the typical sequence

    perl Makefile.PL
    make
    make test
    make install

Make sure you're connected to the Internet while running C<make test>
because it will actually contact amazon.com and run a couple of live tests.

The module's distribution tarball and documentation are available at

    http://perlmeister.com/devel/#amzn 

and on CPAN.

=head1 SEE ALSO

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
