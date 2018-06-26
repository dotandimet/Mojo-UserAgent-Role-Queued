package Mojo::UserAgent::Role::Queued::Queue;

use strict;
use warnings;

use Mojo::Base 'Mojo::EventEmitter';

has jobs => sub { [] };
has active => 0;
has max_active => 4;
has original_method => sub { return sub { die "No Method set!"; } };


sub process {
   my ($self) = @_;
  # we have jobs and can run them:
  while ($self->active < $self->max_active
    and my $job = shift @{$self->jobs})
  {
    my ($tx, $cb) = ($job->{tx}, $job->{cb});
    $self->active($self->active + 1);
    weaken $self;
    $tx->on(finish => sub { $self->active($self->active - 1); $self->process() });
    $self->original_method->( $self, $tx, $cb );
  }
  if (scalar @{$self->jobs} == 0 && $self->active == 0) {
    $self->emit('queue_empty');
  }
}

sub enqueue {
    my ($self, $job) = @_;
    push @{$self->jobs}, $job;
    $self->process();
}

1;
