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
1;
