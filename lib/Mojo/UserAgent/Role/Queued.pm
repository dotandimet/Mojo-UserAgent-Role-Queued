package Mojo::UserAgent::Role::Queued;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

has jobs           => sub { [] };
has timer          => sub {undef};
has queue_max_size => sub { shift->max_connections };

use constant DEBUG => $ENV{MOJO_USERAGENT_ROLE_QUEUED_DEBUG} || 0;

around start => sub {
  my ($orig, $self, $tx, $cb) = @_;
  push @{$self->jobs}, {tx => $tx, cb => $cb};
  return $self->start_queue($orig);
};

sub start_queue {
  my ($self, $original_start) = @_;
  return $self if ($self->timer);
  my $this = $self;
  weaken $this;
  my $orig = $original_start;
  weaken $orig;
  my $id = Mojo::IOLoop->recurring(0 => sub { $this->process($orig); });
  $self->timer($id);
  return $self;
}

sub stop_queue {
  my ($self) = @_;
  if ($self->timer) {
    print STDERR "Stopping...\n" if (DEBUG);
    Mojo::IOLoop->remove($self->timer);
    $self->timer(undef);
  }
  return $self;
}

sub process {
  my ($self, $original_start) = @_;
  state $start //= $original_start;

  # we have jobs and can run them:
  while ($self->active < $self->queue_max_size
    and my $job = shift @{$self->jobs})
  {
    $self->active($self->active + 1);
    my ($tx, $cb) = ($job->{tx}, $job->{cb});
    weaken $tx;
    weaken $cb if (ref $cb eq 'CODE');
    $start->(
      $self, $tx,
      sub {
        my ($ua, $tx1) = @_;
        $ua->active($ua->active - 1);
        $cb->($ua, $tx1) if ($cb);
        $ua->process();
      }
    );
  }
  if (scalar @{$self->jobs} == 0 && $self->active == 0) {
    $self->stop_queue();    # the timer shouldn't run STAM.
  }
}

before DESTROY => sub {
  my ($self) = shift;
  $self->stop_queue();
  $self->jobs(undef);
};


1;
__END__

=encoding utf-8

=head1 NAME

Mojo::UserAgent::Role::Queued - A role to process non-blocking Mojo::UserAgent calls in a rate-limiting queue.

=head1 SYNOPSIS

    use Mojo::UserAgent;

    my $ua = Mojo::UserAgent->new->with_role('+Queued');
    $ua->max_redirects(5);
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

Mojo::UserAgent::Role::Queued is ...

=head1 LICENSE

Copyright (C) Dotan Dimet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Dotan Dimet E<lt>dotan@corky.netE<gt>

=cut

