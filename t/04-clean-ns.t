
use strict;
use warnings;

use Test::More;

{

  package NotMain;

  # namespace::clean->import() messes up compling context and nukes
  # done_testing ...
  use Test::Requires qw( Moo namespace::clean );
}

# ABSTRACT: Basic moo + clean namespaces test
require Moo;
require namespace::clean;
local $@;
my $failed = 1;
eval q[{
  package Sample;
  use Moo;
  use MooX::Lsub;
  use namespace::clean;

  lsub "method"    => sub { 5 };
  lsub "methodtwo" => sub { $_[0]->method + 1 };
  undef $failed;
}];

ok( !$failed, 'No Exceptions' ) or diag $@;
is( Sample->new()->method,    5, 'Injected lazy method returns value' );
is( Sample->new()->methodtwo, 6, 'Injected lazy method returns value' );

done_testing;

