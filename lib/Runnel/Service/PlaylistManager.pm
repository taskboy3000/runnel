package Runnel::Service::PlaylistManager;

use Modern::Perl;

use experimental 'signatures';

sub new ( $class, %args ) {
    my $self = bless {}, $class;

    die "catalog is required" unless exists $args{ catalog };
    $self->catalog($args{ catalog });

    die "playlist is required" unless exists $args{ playlist };
    $self->playlist( $args{ playlist } );

    if ( exists $args{ logger } ) {
        die "logger must be a code ref" unless ref $args{ logger } eq 'CODE';
        $self->logger( $args{ logger } );
    }

    return $self;
}

sub catalog ($self, $object=undef) {
    if (defined $object) {
        $self->{catalog} = $object;
    }

    return $self->{catalog};
}


sub playlist ($self, $object=undef) {
    if (defined $object) {
        $self->{playlist} = $object;
    }

    return $self->{playlist};
}


sub logger ($self, $object=undef) {
    if (defined $object) {
        $self->{logger} = $object;
    }

    return $self->{logger};

}

sub Log ( $self, $level, $msg ) {
    my $logger = $self->logger;
    if ( defined $logger ) {
        $logger->( $level, $msg );
    }
    return;
}

sub add_by_path ( $self, $path ) {
    die "path is required" unless defined $path && $path ne '';

    my $song = $self->catalog->find_by_path( $path );

    die "Song not found: $path" unless $song;

    $self->playlist->add( $song );
    $self->Log(
        info => "Adding to playlist: " . $song->{ info }{ partialPath } );
    return {
        success => 1,
        msg     => sprintf( "Added %s", $song->{ info }{ title } ),
    };
}

sub remove_by_path ( $self, $path ) {
    die "path is required" unless defined $path && $path ne '';

    my $song = $self->catalog->find_by_path( $path );

    die "Song not found: $path" unless $song;

    $self->playlist->remove( $song );
    return {
        success => 1,
        msg     => sprintf( "Removed %s", $song->{ info }{ title } ),
    };
}

sub add_by_artist ( $self, $name ) {
    my $songs = $self->catalog->get_songs( artist => $name );

    for my $song ( @$songs ) {
        $self->playlist->add( $song );
    }

    my $added = scalar @$songs;
    my $msg   = sprintf( "Added %d song%s from artist %s",
        $added, ( $added == 1 ? '' : 's' ), $name );

    return {
        success => 1,
        added   => $added,
        msg     => $msg,
    };
}

sub add_by_album ( $self, $name ) {
    my $songs = $self->catalog->get_songs( album => $name );

    for my $song ( @$songs ) {
        $self->playlist->add( $song );
    }

    my $added = scalar @$songs;
    my $msg   = sprintf( "Added %d song%s from album %s",
        $added, ( $added == 1 ? '' : 's' ), $name );

    return {
        success => 1,
        added   => $added,
        msg     => $msg,
    };
}

sub add_by_genre ( $self, $name ) {
    my $songs = $self->catalog->get_songs( genre => $name );

    for my $song ( @$songs ) {
        $self->playlist->add( $song );
    }

    my $added = scalar @$songs;
    my $msg   = sprintf( "Added %d song%s from genre %s",
        $added, ( $added == 1 ? '' : 's' ), $name );

    return {
        success => 1,
        added   => $added,
        msg     => $msg,
    };
}

sub add_random ( $self, $limit ) {
    $limit //= 100;

    my $songs = $self->catalog->get_random_songs( '', $limit );
    for my $song ( @$songs ) {
        $self->playlist->add( $song );
        $self->Log( info => "Added " . $song->{ info }{ title } );
    }

    return {
        success => 1,
        added   => scalar @$songs,
    };
}

sub clear_all ( $self ) {
    $self->playlist->clear;

    return { success => 1, };
}

1;
