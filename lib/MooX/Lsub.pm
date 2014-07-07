use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package MooX::Lsub;

our $VERSION = '0.001000';

# ABSTRACT: Very shorthand syntax for bulk lazy builders

# AUTHORITY

=head1 SYNOPSIS

  use MooX::Lsub;

  # Shorthand for
  # has foo => ( is => ro =>, lazy => 1, builder => sub { "Hello" });

  lsub foo => sub { "Hello" };


=head1 DESCRIPTION

I often want to use a lot of lazy build subs to implement some plumbing, with scope to allow
it to be overridden by people who know what they're doing with an injection library like Bread::Board.

Usually, the syntax of C<Class::Tiny> is what I use for such things.

  use Class::Tiny {
    'a' => sub { },
    'b' => sub { },
  };

Etc.

But switching things to Moo means I usually have to get much uglier, and repeat myself a *lot*.

So this module exists as a compromise.

Additionally, I always forgot to declare C<use Moo 1.000008> which was the first version of C<Moo> where C<< builder => sub >> worked, and I would invariably get silly test failures in smokers as a consequence.

This module avoids such problem entirely, and is tested to work with C<Moo 0.009001>.

=cut

use Eval::Closure;

sub _get_sub {
  my ( $class, $target, $subname ) = @_;
  no strict 'refs';
  return \&{ $target . '::' . $subname };
}

sub _set_sub {
  my ( $class, $target, $subname, $code ) = @_;
  no strict 'refs';
  *{ $target . '::' . $subname } = $code;
}

sub import {
  my ( $class, @args ) = @_;
  my $target = caller;
  my $has = $class->_get_sub( $target, 'has' );

  die "No 'has' method in $target. Did you forget to import Moo(se)?" if not $has;

  my $lsub_code = $class->_make_lsub(
    {
      target  => $target,
      has     => $has,
      options => \@args,
    }
  );

  $class->_set_sub( $target, 'lsub', $lsub_code );

  return;
}

sub _make_lsub {
  my ( $class, $options ) = @_;

  my $nl   = qq[\n];
  my $code = 'sub($$) {' . $nl;
  $code .= q[ package ] . $class . q[; ] . $nl;
  $code .= q[ my ( $subname, $sub , @extras ) = @_; ] . $nl;
  $code .= q[ if ( @extras ) { ] . $nl;
  $code .= q[   die "Too many arguments to 'lsub'. Did you misplace a ';'?"; ] . $nl;
  $code .= q[ } ] . $nl;
  $code .= q[ if ( not defined $subname or not length $subname or ref $subname ) { ] . $nl;
  $code .= q[   die "Subname must be defined + length + not a ref"; ] . $nl;
  $code .= q[ } ] . $nl;
  $code .= q[ if ( not 'CODE' eq ref $sub ) { ] . $nl;
  $code .= q[   die "Sub must be a CODE ref"; ] . $nl;
  $code .= q[ } ] . $nl;
  $code .= q[ $class->_set_sub($target, "_build_" . $subname , $sub ); ] . $nl;
  $code .= q[ package ] . $options->{'target'} . q[; ] . $nl;
  $code .= q[ return $has->( $subname, is => 'ro', lazy => 1, builder => '_build_' . $subname ); ] . $nl;
  $code .= q[}] . $nl;

  my $sub = eval_closure(
    source      => $code,
    environment => {
      '$class'  => \$class,
      '$has'    => \$options->{'has'},
      '$target' => \$options->{'target'},
    },
  );
  return $sub;
}

1;
