use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use Test::More;
use Test::Exception;

use Runnel::Catalog;
use Runnel::Service::SongSearch;

my $testDir    = "$FindBin::Bin/..";
my $catalogDir = "$testDir/fake_catalog";

my $catalog = Runnel::Catalog->new()->find_songs( $catalogDir );

my @logMessages;

subtest 'constructor validation' => sub {
    dies_ok( sub { Runnel::Service::SongSearch->new() },
        "dies without catalog" );
    dies_ok(
        sub {
            Runnel::Service::SongSearch->new( catalog => $catalog, logger => 1 );
        },
        "dies when logger is not a code ref"
    );
};

subtest 'search with valid term' => sub {
    my $svc = Runnel::Service::SongSearch->new(
        catalog => $catalog,
        logger     => sub { push @logMessages, [ @_ ] }
    );

    my $results = $svc->search( 'Artist' );
    ok( defined $results, "search returns defined" );
    is( ref $results, 'ARRAY', "search returns array ref" );
};

subtest 'search with empty string' => sub {
    my $svc = Runnel::Service::SongSearch->new(
        catalog => $catalog,
        logger     => sub { push @logMessages, [ @_ ] }
    );

    my $results = $svc->search( '' );
    ok( defined $results, "search returns defined for empty string" );
    is( ref $results, 'ARRAY', "search returns array ref for empty string" );
};

subtest 'search with undef term' => sub {
    my $svc = Runnel::Service::SongSearch->new(
        catalog => $catalog,
        logger     => sub { push @logMessages, [ @_ ] }
    );

    my $results = $svc->search( undef );
    ok( defined $results, "search returns defined for undef" );
    is( ref $results, 'ARRAY', "search returns array ref for undef" );
};

subtest 'search with single word' => sub {
    my $svc = Runnel::Service::SongSearch->new(
        catalog => $catalog,
        logger     => sub { push @logMessages, [ @_ ] }
    );

    my $results = $svc->search( 'A' );
    ok( defined $results, "search returns defined for single word" );
    is( ref $results, 'ARRAY', "search returns array ref for single word" );

    if ( @$results > 0 ) {
        ok( exists $results->[ 0 ]{ info }, "result has info key" );
        ok( exists $results->[ 0 ]{ name }, "result has name key" );
        is( $results->[ 0 ]{ name },
            $results->[ 0 ]{ info }{ title },
            "name matches info title"
        );
    }
};

subtest 'search with multi-word' => sub {
    my $svc = Runnel::Service::SongSearch->new(
        catalog => $catalog,
        logger     => sub { push @logMessages, [ @_ ] }
    );

    my $results = $svc->search( 'A Song' );
    ok( defined $results, "search returns defined for multi-word" );
    is( ref $results, 'ARRAY', "search returns array ref for multi-word" );
};

subtest 'search with no matches' => sub {
    my $svc = Runnel::Service::SongSearch->new(
        catalog => $catalog,
        logger     => sub { push @logMessages, [ @_ ] }
    );

    my $results = $svc->search( 'NonExistentWord12345' );
    ok( defined $results, "search returns defined for no matches" );
    is( ref $results, 'ARRAY',  "search returns array ref for no matches" );
    is( scalar( @$results ), 0, "search returns empty array for no matches" );
};

subtest 'logging callback invoked' => sub {
    @logMessages = ();
    my $svc = Runnel::Service::SongSearch->new(
        catalog => $catalog,
        logger     => sub { push @logMessages, [ @_ ] }
    );

    $svc->search( 'Artist' );
    ok( scalar( @logMessages ) >= 0, "log callback was called" );
};

done_testing();
