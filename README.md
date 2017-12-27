# NAME

Mojo::UserAgent::Role::Queued - A role to process non-blocking requests in a rate-limiting queue.

# SYNOPSIS

       use Mojo::UserAgent;

       my $ua = Mojo::UserAgent->new->with_role('+Queued');
       $ua->max_redirects(3);
       $ua->queue_max_size(5); # process up to 5 requests at a time
       for my $url (@big_list_of_urls) {
       $ua->get($url, sub {
               my ($ua, $tx) = @_;
               if ($tx->success) {
                   say "Page at $url is titled: ",
                     $tx->res->dom->at('title')->text;
               }
              });
      }
    

# DESCRIPTION

Mojo::UserAgent::Role::Queued manages all non-blocking requests made through [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent) in a queue to limit the number of simultaneous requests.

[Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent) can make multiple concurrent non-blocking HTTP requests using Mojo's event loop, but because there is only a single process handling all of them, you must take care to limit the number of simultaneous requests you make.

Some discussion of this issue is available here
[http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html](http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html)
and in Joel Berger's answer here:
[http://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests](http://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests).

[Mojo::UserAgent::Role::Queued](https://metacpan.org/pod/Mojo::UserAgent::Role::Queued) tries to generalize the practice of managing a large number of requests using a queue, by embedding the queue inside [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent) itself.

# ATTRIBUTES

[Mojo::UserAgent::Role::Queued](https://metacpan.org/pod/Mojo::UserAgent::Role::Queued) has the following attributes:

# LICENSE

Copyright (C) Dotan Dimet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Dotan Dimet <dotan@corky.net>
