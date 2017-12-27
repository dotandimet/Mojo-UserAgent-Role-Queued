use Mojo::UserAgent;
use Mojo::IOLoop;

my $ua    = Mojo::UserAgent->new;
my $mcpan = Mojo::URL->new('https://metacpan.org');
my $search
  = Mojo::URL->new('/search?p=1&q=web+framework&size=500')->to_abs($mcpan);
my %reviews = ();
$ua->get(
  $search,
  sub {
    my ($ua, $tx) = @_;
    my @urls
      = $tx->res->dom->find('.module-result big a')->map('attr', 'href')
      ->map(sub { Mojo::URL->new($_)->to_abs($mcpan) })->each(
      sub {
        $ua->get(
          $_,
          sub {
            my $tx  = pop;
            my $rev = $tx->res->dom->at('span [itemprop=reviewcount]');
            $reviews{$tx->req->url} = ($rev) ? $rev->text : 0;
          }
        );
      }
      );
  }
);
Mojo::IOLoop->start unless (Mojo::IOLoop->is_running);

END {
    print "The End, folks\n";
    for my $fwork (sort { $reviews{$b} <=> $reviews{$a} } (keys %reviews)) {
        print $fwork, " ", $reviews{$fwork} , " reviews\n";
    }
}
