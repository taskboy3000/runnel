package Runnel::Controller;

use Mojo::Base 'Mojolicious::Controller', '-signatures';

sub short_name ($self) {
    my $n = ref($self);
    $n =~ s/^((\w+)::){2}//;
    $n =~ s/::/_/g;
    return lc($n);
}

1;
