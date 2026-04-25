package Runnel::Service::SongSearch;

use Modern::Perl;

use experimental 'signatures';

sub new ( $class, %args ) {
    my $self = bless {}, $class;

    die "catalog is required" unless exists $args{ catalog };
    $self->{ catalog } = $args{ catalog };

    if ( exists $args{ logger } ) {
        die "logger must be a code ref" unless ref $args{ logger } eq 'CODE';
        $self->logger( $args{ logger } );
    }

    return $self;
}

sub logger ( $self, $object = undef ) {
    if ( defined $object ) {
        $self->{ logger } = $object;
    }

    return $self->{ logger };
}

sub search ( $self, $term = '' ) {
    my @words;
    if ( defined $term && $term ne '' ) {
        @words = split( /\s+/, $term );
    }

    my $found = $self->{ catalog }->search( \@words );

    my $catalogFormat = [];
    for my $info ( @$found ) {
        push @$catalogFormat,
            {
            info => $info,
            name => $info->{ title },
            };
    }

    return $catalogFormat;
}

1;
