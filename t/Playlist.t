use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;

use Runnel::Playlist;

my $P = Runnel::Playlist->new;

ok( defined $P, "Playlist object created" );
isa_ok( $P, "Runnel::Playlist" );

ok( eq_array( $P->list, [] ), "Initial list is empty" );

subtest "test add()" => sub {
    my $item1 = { info => { title => "Song A", track => 1 } };
    my $item2 = { info => { title => "Song B", track => 2 } };

    $P->add( $item1 );
    ok( @{ $P->list } == 1, "Added first item" );

    $P->add( $item2 );
    ok( @{ $P->list } == 2, "Added second item" );

    $P->add( $item1 );
    ok( @{ $P->list } == 2, "Did not add duplicate" );
};

subtest "test remove()" => sub {
    my $P2    = Runnel::Playlist->new;
    my $item1 = { info => { title => "Song A" } };
    my $item2 = { info => { title => "Song B" } };

    $P2->add( $item1 );
    $P2->add( $item2 );
    ok( @{ $P2->list } == 2, "Has 2 items before remove" );

    $P2->remove( $item1 );
    ok( @{ $P2->list } == 1, "Has 1 item after remove" );
};

subtest "test clear()" => sub {
    my $P3 = Runnel::Playlist->new;
    $P3->add( { info => { title => "Song A" } } );
    $P3->add( { info => { title => "Song B" } } );

    $P3->clear;
    ok( @{ $P3->list } == 0, "List is empty after clear" );
};

subtest "test sort_by_track_number()" => sub {
    my $P4 = Runnel::Playlist->new;
    $P4->add( { info => { track => 3, partialPath => "c.mp3" } } );
    $P4->add( { info => { track => 1, partialPath => "a.mp3" } } );
    $P4->add( { info => { track => 2, partialPath => "b.mp3" } } );

    my $sorted = $P4->sort_by_track_number;
    ok( @$sorted == 3, "Sorted list has 3 items" );
    is( $sorted->[ 0 ]{ info }{ track }, 1, "First track is 1" );
    is( $sorted->[ 1 ]{ info }{ track }, 2, "Second track is 2" );
    is( $sorted->[ 2 ]{ info }{ track }, 3, "Third track is 3" );
};

subtest "test sort_by_path()" => sub {
    my $P5 = Runnel::Playlist->new;
    $P5->add( { info => { partialPath => "c.mp3" } } );
    $P5->add( { info => { partialPath => "a.mp3" } } );
    $P5->add( { info => { partialPath => "b.mp3" } } );

    my $sorted = $P5->sort_by_path;
    ok( @$sorted == 3, "Sorted list has 3 items" );
    is( $sorted->[ 0 ]{ info }{ partialPath },
        "a.mp3", "First path is a.mp3" );
    is( $sorted->[ 1 ]{ info }{ partialPath },
        "b.mp3", "Second path is b.mp3" );
    is( $sorted->[ 2 ]{ info }{ partialPath },
        "c.mp3", "Third path is c.mp3" );
};

done_testing();
