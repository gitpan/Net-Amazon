# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Net::Amazon') };

use Net::Amazon::Request::Wishlist;
use Net::Amazon::Response::Wishlist;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level  => $DEBUG, file => "STDOUT",
#                          layout => "%F{1}%L> %m%n" });

######################################################################
# Successful Wishlist fetch
######################################################################
my $ua = Net::Amazon->new(
    token       => 'YOUR_AMZN_TOKEN',
);

my $req = Net::Amazon::Request::Wishlist->new(
    id  => '3W25UPFJVC46G'
);

   # Response is of type Net::Amazon::ASIN::Response
my $resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");
like($resp->as_string(), qr#Richard M. Stallman/Lawrence Lessig/Joshua Gay#, "Found Stallman");
