package Class::Pluggable;

use 5.008006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.021';

sub import {
  my ($self) = @_;
  my @plugins = ();
  my $package = __PACKAGE__;

  { ## Create closure that returns array reference for the plugins.
	no strict "refs";
	if (not defined &{"${package}::_getPlugins"}) {
	  *{"${package}::_getPlugins"} = sub {
		return \@plugins;
	  }
	}
  }
}

sub addPlugin {
	my ($self, $plugin) = @_;

	push @{$self->_getPlugins()}, $plugin;

	{
	  no strict 'refs';
	  s/^&//, *{"$_"} = \&{"${plugin}::$_"}
		foreach @{"${plugin}::EXPORT_AS_PLUGIN"};
	}
}


sub getPlugins {
  return @{$_[0]->_getPlugins()};
}


sub addHook {
  my ($self, $hook, $method) = @_;

  if (defined ${$self->{_HOOK}}{$hook}) {
	carp("The hook ($hook) already in used. It will overwrite with new method.");
  }

  ${$self->{_HOOK}}{$hook} = $method;
}


sub runHook {
  my ($self, $hook) = @_;
  my $method = ${$self->{_HOOK}}{$hook};

  if (not defined $method) {
	my $caller = caller(0);
	croak("The hook ($hook) $caller called doesn't exists.");
  }

  $self->executeAllPluginsMethod($method);
}



sub removeHook {
  my ($self, $hook) = @_;
  delete ${$self->{_HOOK}}{$hook};
}


sub executePluginMethod {
	my ($self, $plugin, $method, @args) = @_;
	my $result;

	if (defined &{"${plugin}::$method"}) {
	  # Give $self to make the plugin method looks like object method.
	  {
		no strict 'refs';
		$result = &{"${plugin}::$method"}($self, @args);
	  }
	}
	return $result;
}

sub executeAllPluginsMethod {
  my ($self, $method, @args) = @_;

  $self->executePluginMethod($_, $method, @args)
	foreach $self->getPlugins();
}

1;
__END__

=head1 NAME

Class::Pluggable - Simple pluggable class.

=head1 SYNOPSIS

  use Class::Pluggable;
  use base qw(Class::Pluggable);

  # Some::Plugin::Module has sub routin called newAction
  addPlugin("Some::Plugin::Module"); 

  newAction();  # Plugged action.

=head1 DESCRIPTION

This class makes your class (sub class of Class::Pluggable) pluggable.
In this documentatin, the word "pluggable" has two meanings.

One is just simply adding new method to your pluggable classs from 
other plugin modules. So, after you plugged some modules to your class,
you can use there method exactly same as your own object method.

You can see this kind of plugin mechanism in CGI::Application and
CGI::Application::Plugin::Session.

There are one thing that Plugin developer have to know. The plugin
module MUST have @EXPORT_AS_PLUGIN to use this pluggable mechanism.
This works almost same as @EXPORT. But the methods in the
@EXPORT_AS_PLUGIN wouldn't be exported to your package. But it would
be exported to the subclass of Class::Pluggable (only when you call addPlugin()).

And the another meaning of "pluggable" is so called hook-mechanism.
For example, if you want to allow to other modules to do something
before and/or after some action. You can do like this:

  $self->executePluginMethod($_, "before_action")
    foreach $self->getPlugins();

  ## do some your own action here.

  $self->executePluginMethod($_, "after_action")
    foreach $self->getPlugins();

=head1 METHODS

Here are all methods of Class::Pluggable.

=over 4

=item addPlugin

  YourClass->addPlugin($pluginName)

This will add new plugin to your class. What you added to here
would be returned by getPlugins() method.

=item getPlugins

  @plugins = YourClass->getPlugins();

It will return all of plugin names that are already added to YouClass.

=item executePluginMethod

  $result = YourClass->executePluginMethod("SomePlugin", "someMethod");

This will execute the method someMethod of SomePlugin.

=item executeAllPluginMethod

  YourClass->executeAllPluginMethod("someMethod");

This will execute the method someMethod of all plugin we have.
This is almost same as following code.

  $self->executePluginMethod($_, "someMethod")
    foreach $self->getPlugins();

The difference is executeAllPluginMethod can't return any values.
But executePluginMethod can.

=item addHook

  YourClass->addHook("pre-init", "pre_init");

This will add new hook to your class. Whenever runHook("pre-init") has called,
the method pre_init of all plugins which we have will be executed.

=item runHook

  YourClass->runHook("pre-init");

This will execute the hook-method of all plugins which we have.

=item deleteHook

  YourClass->deleteHook("pre-init");

This will delete the hook from YourClass. After calling this method,
you cannot call runHook("pre-init"). If you do, it will die immediately.

=head1 SEE ALSO

...

=head1 AUTHOR


Ken Takeshige, E<lt>ken.takeshige@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ken Takeshige

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
