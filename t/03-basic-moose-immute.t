
use strict;
use warnings;

use Test::More;
use Test::Requires qw( Moose );

# ABSTRACT: Basic moo test
local $@;
my $failed = 1;
eval q[{
  package Sample;
  use Moose;
  use MooX::Lsub;

  lsub "method"    => sub { 5 };
  lsub "methodtwo" => sub { $_[0]->method + 1 };
  __PACKAGE__->meta->make_immutable;
  undef $failed;
}];
ok( !$failed, 'No Exceptions' ) or diag $@;
is( Sample->new()->method,    5, 'Injected lazy method returns value' );
is( Sample->new()->methodtwo, 6, 'Injected lazy method returns value' );

done_testing;

