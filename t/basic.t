use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Carp;

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

chdir $FindBin::Bin;    # needs to be in t for the yml catalog path
$ENV{ RUNNEL_YML } = "$FindBin::Bin/runnel-test.yml";
ok( -e $ENV{ RUNNEL_YML }, "Test configuration is present" );

eval {
    my $t = Test::Mojo->new( 'Runnel' );

    $t->get_ok( '/' )->status_is( 200 )
        ->content_like( qr!<title>Runnel</title>! );
    1;
} or do {
    carp( "WARN> $@" );
};

done_testing();
