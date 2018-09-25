use Mojo::Base -strict;
use Test::More;
use constant RELEASE_TESTING => $ENV{RELEASE_TESTING};

BEGIN {
  if (RELEASE_TESTING) {
    require Test::Memory::Cycle;
    Test::Memory::Cycle->import();
  }
  else {
    plan skip_all => 'test for memory leaks';
  }
}

use Mojo::UserAgent;

use Mojolicious::Lite;

get '/:foo' => sub {
  my $c   = shift;
  my $foo = $c->stash('foo');
  $c->render(text => "Hello $foo");
};

my $ua = Mojo::UserAgent->new->with_roles('+Queued');
$ua->max_active(2);

# relative urls will be fetched from the Mojolicious::Lite app defined above
$ua->server->app(app);
$ua->server->app->log->level('fatal');

my @tests_p;
for my $name (qw(fred barney wilma peebles bambam dino)) {
  @tests_p
    = $ua->get_p("/$name")->then(sub { shift->res->content eq "Hello $name" });
}
memory_cycle_ok($ua);

Mojo::Promise->all(@tests_p)->wait;

done_testing();
