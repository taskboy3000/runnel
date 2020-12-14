package Runnel::Controller::Songs;
use Mojo::Base 'Mojolicious::Controller', '-signatures';

sub index ($self) {
    $self->app->log->info("Hello");
    $self->stash("songs" => $self->app->catalog->songs);
    $self->render();
}

1;
