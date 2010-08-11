#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'RSSBot' ) || print "Bail out!
";
}

diag( "Testing RSSBot $RSSBot::VERSION, Perl $], $^X" );
