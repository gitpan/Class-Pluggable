package SamplePluggable;

use Class::Pluggable;
use base qw(Class::Pluggable);

sub new {
  return bless {}, shift;
}

sub hello {
  return "hello";
}


1;
