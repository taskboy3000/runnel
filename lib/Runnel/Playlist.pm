package Runnel::Playlist;
use Mojo::Base '-base', '-signatures';
no warnings 'experimental::signatures';

has 'list' => sub { [] };

sub add ( $self, $item ) {
    for my $el ( @{ $self->list } ) {
        if ( $item eq $el ) {
            return;    # already added
        }
    }
    push @{ $self->list }, $item;
}

sub remove ( $self, $item ) {
    my @tmp;
    for my $el ( @{ $self->list } ) {
        if ( $item ne $el ) {
            push @tmp, $el;
        }
    }
    @{ $self->list } = @tmp;
}


sub clear ( $self ) {
    @{ $self->list } = ();
}


sub sort_by_track_number ( $self ) {
    return [ sort { $a->{ info }->{ track } <=> $b->{ info }->{ track } }
            @{ $self->list } ];
}


sub sort_by_path ( $self ) {
    return [
        sort {
            $a->{ info }->{ partialPath } cmp $b->{ info }->{ partialPath }
        } @{ $self->list }
    ];
}

1;
