
use strict;
use warnings;

use Test::More;

{

  package NotMain;

  # namespace::autoclean->import() messes up compling context and nukes
  # done_testing, is, etc....
  use Test::Requires qw( Moo namespace::autoclean );
}

# ABSTRACT: Basic moo + clean namespaces test

local $@;
my $failed = 1;
eval q[{
  package Sample;
  use Moo;
  use MooX::Lsub;
  use namespace::autoclean;

  lsub "method"    => sub { 5 };
  lsub "methodtwo" => sub { $_[0]->method + 1 };
  undef $failed;
}];
ok( !$failed, 'No Exceptions' ) or diag $@;
is( Sample->new()->method,    5, 'Injected lazy method returns value' );
is( Sample->new()->methodtwo, 6, 'Injected lazy method returns value' );

done_testing();

