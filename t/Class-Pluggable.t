#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;

######################## APlugin
package APlugin;

use vars qw(@EXPORT_AS_PLUGIN);

@EXPORT_AS_PLUGIN = qw(&foo &bar &hoge &getHookCounter);

my $hook_counter = 0;
sub foo { return "foo"; }
sub bar { return "bar"; }
sub hoge { return "hoge"; }

sub beforeAction {
  return "Plugin::APlugin::beforeAction";
}

sub afterAction {
  return "Plugin::APlugin::afterAction";
}

sub sampleHook {
  return ++$hook_counter;
}

sub getHookCounter {
  return $hook_counter;
}


######################### SamplePluggable
package SamplePluggable;

use Class::Pluggable;
use base qw(Class::Pluggable);

sub new {
  return bless {}, shift;
}

sub hello {
  return "hello";
}

######################### main
package main;

BEGIN { use_ok('Class::Pluggable') };
#use APlugin;
#use SamplePluggable;


my $sample = new SamplePluggable();

is (scalar($sample->getPlugins()), 0, "initial size of plugins");

$sample->addPlugin("APlugin");

is (scalar $sample->getPlugins(), 1, "final size of plugins");

is ("hello", $sample->hello(), 'original method');
is ("foo",   $sample->foo(),   'plugged method(foo)');
is ("bar",   $sample->bar(),   'plugged method(bar)');
is ("hoge",  $sample->hoge(),  'plugged method(hoge)');

is ("Plugin::APlugin::beforeAction",
    $sample->executePluginMethod("APlugin", "beforeAction"), "hook test");
is ("Plugin::APlugin::afterAction",
    $sample->executePluginMethod("APlugin", "afterAction"), "hook test");

## This method doesn't exists.
## So, it should return undef.

is (undef,
    $sample->executePluginMethod("APlugin", "methodWhichDoesntExists"),
	"non-exists hook");

$sample->addHook('hook', 'sampleHook');
$sample->runHook('hook');
$sample->runHook('hook');

eval { ## This should die. Because of the hook doesn't exists.
	 $sample->runHook('hoo2');
};
if ($@) {
   pass("Executing hook doesn't exists.");
}
else {
	 fail("Executing hook doesn't exists.");
}
is ($sample->getHookCounter(), 2, "Running hook method.");
