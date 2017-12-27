package Mojo::UserAgent::Role::Queued;
use Mojo::Base '-role';
use Scalar::Util 'weaken';

our $VERSION = "0.01";

has jobs           => sub { [] };
has timer          => undef;
has queue_max_size => sub { shift->max_connections };
has active         => 0;

use constant DEBUG => $ENV{MOJO_USERAGENT_ROLE_QUEUED_DEBUG} || 0;

around start => sub {
  my ($orig, $self, $tx, $cb) = @_;
  if ($cb) {
    push @{$self->jobs}, {tx => $tx, cb => $cb};
    $self->_start_queue($orig);
  }
  else {
    return $orig->($self, $tx); # Blocking skip the queue
  }
};

sub _start_queue {
  my ($self, $original_start) = @_;
  return $self if ($self->timer);
  my $this = $self;
  weaken $this;
  my $orig = $original_start;
  weaken $orig;
  my $id = Mojo::IOLoop->recurring(0 => sub { $this->_process($orig); });
  $self->timer($id);
#  Mojo::IOLoop->start unless Mojo::IOLoop->is_running; # or the queue won't start...
}

sub _stop_queue {
  my ($self) = @_;
  if ($self->timer) {
    print STDERR "Stopping...\n" if (DEBUG);
    Mojo::IOLoop->remove($self->timer);
    $self->timer(undef);
  }
  return $self;
}

sub _process {
  my ($self, $original_start) = @_;
  state $start //= $original_start;

  # we have jobs and can run them:
  while ($self->active < $self->queue_max_size
    and my $job = shift @{$self->jobs})
  {
    my ($tx, $cb) = ($job->{tx}, $job->{cb});
    $self->active($self->active + 1);
    $start->( $self, $tx,
              sub {
                    my ($ua, $tx1) = @_;
                    $ua->active($ua->active - 1);
                    $cb->($ua, $tx1);
                    $ua->_process();
        });
  }
  if (scalar @{$self->jobs} == 0 && $self->active == 0) {
    $self->emit('stop_queue');
    $self->_stop_queue();    # the timer shouldn't run STAM.
  }
}

before DESTROY => sub {
  my ($self) = shift;
  $self->_stop_queue();
  $self->jobs(undef);
};


1;
__END__

=encoding utf-8

=head1 NAME

Mojo::UserAgent::Role::Queued - A role to process non-blocking requests in a rate-limiting queue.

=head1 SYNOPSIS

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
 

=head1 DESCRIPTION

Mojo::UserAgent::Role::Queued manages all non-blocking requests made through L<Mojo::UserAgent> in a queue to limit the number of simultaneous requests.

L<Mojo::UserAgent> can make multiple concurrent non-blocking HTTP requests using Mojo's event loop, but because there is only a single process handling all of them, you must take care to limit the number of simultaneous requests you make.

Some discussion of this issue is available here
L<http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html>
and in Joel Berger's answer here:
L<http://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests>.

L<Mojo::UserAgent::Role::Queued> tries to generalize the practice of managing a large number of requests using a queue, by embedding the queue inside L<Mojo::UserAgent> itself.

=head1 ATTRIBUTES

L<Mojo::UserAgent::Role::Queued> has the following attributes:


=head1 LICENSE

Copyright (C) Dotan Dimet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Dotan Dimet E<lt>dotan@corky.netE<gt>

=cut

