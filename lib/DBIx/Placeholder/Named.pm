package DBIx::Placeholder::Named;

use warnings;
use strict;

use base qw(DBI);
our $VERSION = '0.05';

package DBIx::Placeholder::Named::db;

use SQL::Tokenizer;
use Data::Dumper;
use base qw(DBI::db);

sub prepare {
    my ( $dbh, $query ) = @_;

    # each token is analyzed. if the token starts with ':', it is pushed to
    # @tao_dbi_placeholders. each element represents the named placeholder,
    # and its index represents the order we will create the
    # DBI::st::execute()'s argument (see Tao::DBI::st::execute()).
    #
    # TODO: someday we can benchmark this piece of code and check if using
    # substr is more efficient.
    my @placeholders;
    my @query_tokens = SQL::Tokenizer->tokenize($query);

    foreach my $token (@query_tokens) {
        if ( substr( $token, 0, 1 ) eq ':' ) {
            push @placeholders, substr( $token, 1 );
            $token = '?';
        }
    }

    my $new_query = join '', @query_tokens;

    # it's time to call DBI::st::prepare(). we use the modified tokenized
    # query (with all named placeholders substituted by '?').
    my $sth = $dbh->SUPER::prepare($new_query)
      or return;

    # we can now store the named placeholders array.
    $sth->{private_dbix_placeholder_named_info} =
      { placeholders => \@placeholders };

    return $sth;
}

package DBIx::Placeholder::Named::st;

use base qw(DBI::st);

sub execute {
    my $sth = shift;

    my @params;

    if ( ref $_[0] eq 'HASH' ) {

        # create the DBI::st::execute()'s parameter. we iterate each named
        # placeholder stored in Tao::DBI::db::prepare() and retrieve its value
        # from the user supplied dictionary.

        @params =
          map { $_[0]->{$_} }
          @{ $sth->{private_dbix_placeholder_named_info}->{placeholders} };
    }
    else {

        # user haven't supplied a dictionary, so we use the parameters 'as is'
        @params = @_;
    }

    # DBI::st::execute() always returns.
    my $rv = $sth->SUPER::execute(@params);

    return $rv;
}

1;

=pod

=head1 NAME

DBIx::Placeholder::Named - DBI with named placeholders

=head1 SYNOPSIS

use DBIx::Placeholder::Named;

my $dbh = DBIx::Placeholder::Named->connect($dsn, $user, $password)
  or die DBIx::Placeholder::Named->errstr;

my $sth = $dbh->prepare(
  q{INSERT INTO some_table (this, that) VALUES (:this, :that)}
)
  or die $dbh->errstr;

$sth->execute({ this => $this, that => $that, });

=head1 DESCRIPTION

DBIx::Placeholder::Named is a subclass of DBI, which implements the ability 
to understand named placeholders.

=head1 AUTHOR

Copyright (c) 2007, Igor Sutton Lopes "<IZUT@cpan.org>". All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<SQL::Tokenizer>

=cut

