#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('DBIx::Placeholder::Named');
}

diag(
"Testing DBIx::Placeholder::Named $DBIx::Placeholder::Named::VERSION, Perl $], $^X"
);
