package Runnel::Command::scan;
use Mojo::Base 'Mojolicious::Command', -signatures;

has description => 'Scan the music catalog';

sub startup () {}

sub run ($self, @args) {
    $self->app->catalog_scan;
}

1;