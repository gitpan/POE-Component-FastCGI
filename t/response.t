#!/usr/bin/perl
use Test::Simple tests => 6;
my($destroy, $put);

use POE::Component::FastCGI::Response;
# loaded
ok(1);

my $response = POE::Component::FastCGI::Response->new(
	bless({}, __PACKAGE__), # see callbacks at the end
	1,
	200
);

ok(ref $response and $response->isa("POE::Component::FastCGI::Response"));

$response->redirect("http://www.perl.org/");
$response->send;
ok($put->{content} =~ m!Location:\s*http://www\.perl\.org/!);

$put = undef;
$response = POE::Component::FastCGI::Response->new(
	bless({}, __PACKAGE__),
	1,
	404,
	"Not Found",
	HTTP::Headers->new('Content-type' => 'text/html'),
	"not found?"
);

ok($response->send && $put->{close});
ok($put->{content} =~ m!^Status: 404.*Content-type:\s*text/html.*not found\?$!si);

$put = $destroy = undef;
$response = POE::Component::FastCGI::Response->new(
	bless({}, __PACKAGE__),
	1
);
undef $response;
ok($destroy && $put->{close});

# callbacks..
sub DESTROY { $destroy = 1; }
sub put { $put = $_[1]; }

