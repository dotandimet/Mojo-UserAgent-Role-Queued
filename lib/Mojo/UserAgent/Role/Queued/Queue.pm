package Mojo::UserAgent::Role::Queued::Queue;
use Mojo::Base -base;

has jobs => sub { [] };
has active => 0;
has concurrency => 4;
has start => undef, weak => 1;
has ua => undef, weak => 1;


sub process {
   my ($self) = @_;
  # we have jobs and can run them:
  while ( $self->active < $self->concurrency
          and not $self->is_empty )
  {
    $self->active($self->active + 1);
    my ($tx, $cb) = $self->dequeue();
    $self->start->($self->ua, $tx, $cb );
  }
  if ($self->is_empty && $self->active == 0) {
    $self->ua->emit('queue_empty');
  }
}

sub tx_finish {
    my ($self) = @_;
    $self->active($self->active - 1);
    $self->process();
}

sub enqueue {
    my ($self, $tx, $cb) = @_;
    my $job = [$tx, $cb];
    push @{$self->jobs}, $job;
    $self->process();
}

sub dequeue {
    my ($self) = @_;
    my $job = shift @{$self->jobs};
    my $tx = shift @$job;
    my $cb = shift @$job;
    $tx->on(finish => sub { $self->tx_finish(); });
    return ($tx, $cb);
}

sub is_empty {
    return @{$_[0]->jobs} == 0;
}

1;
