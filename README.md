# Change Risk

## Description

Let "Arbiter" be a service that provides change risk assessment information for a given node at the current time. Further, let Arbiter be assumed to consider information from ServiceNow—node ownership, escalation status, maintenance window, peak business hours, other data points—and produce a simple matrix of change risk-to-permitted decisions. Low-risk change: permitted. Medium-risk change: not permitted. And so forth.

This module provides Puppet code patterns and constructs that let developers declare their code with change risk information. The constructs will allow Puppet to selectively and automatically tag and/or no-op configuration elements according to the current change risk tolerance permitted by Arbiter.

## Basic Usage

### Step 1: configure permissible change risk levels

For testing or semi-permanent configuration, this can just be done in Hiera yaml.

```yaml
change_risk::permitted_risk:
  high:    false,
  medium:  true,
  low:     true,
  unknown: true,
```

### Step 2: use `change_risk()` in code

To mark a class with an assessed change risk, call the `change_risk()` function at the top of the class.

```puppet
class profile::dangerous {
  change_risk('high')

  # ...
}
```

To mark a non-class block of code with an assessed change risk, call the `change_risk()` function with a block.

```puppet
change_risk('medium') || {
  file { '/etc/postfix/main.cf':
    source => 'puppet:///modules/postfix/main.cf',
  }

  service { 'postfix':
    ensure    => running,
    subscribe => File['/etc/postfix/main.cf'],
  }
}
```

### Step 3: run Puppet

When Puppet runs it will no-op resources that have a change-risk level which is not currently permitted. Resources that don't have an assessed change-risk level, or with a permitted change-risk level will be applied in op mode.

### Step 4: use change-risk information in reporting

PQL queries can return information about resources in node catalogs and their assessed change-risk levels. Resources will have been tagged with a tag of the form "change\_risk:\<level\>". E.g. "change\_risk:high" or "change\_risk:low".

```shell
puppet query 'resources { certname = "my-node" and tags = "change_risk:high" }'
```

## Setup

The behavior of the change\_risk function is controlled through a configuration class. The configuration can be set by providing the appropriate settings using Hiera data (preferred), or by declaring the class resource-style in site.pp (only recommended for testing purposes).

In the examples below the risk tolerance data shown is static. In a real-world scenario, the `$permitted_risk` configuration parameter could be supplied dynamically using either a Puppet function call to query a service such as Arbiter, or by querying Arbiter data using a `trusted_external_command` integration.

### Hiera Data Example

```yaml
change_risk::permitted_risk:
  high:    false,
  medium:  true,
  low:     true,
  unknown: true,

change_risk::risk_not_found_action: fail
change_risk::ignore_permitted_risk: false
change_risk::disable_mechanism: flag
change_risk::respect_noop_class_interface: true
```

The only required parameter is `change_risk::permitted_risk`. The remaining parameters have acceptable defaults. For more information on each of these parameters and what they affect, see the [Reference](#reference) section.

### Using With External Data Sources

If change risk data is coming from a system like Arbiter, it can be consumed in Puppet either by:

* Using the `trusted_external_command` feature
* Supplying the data through an ENC, as a top-scope variable
* Supplying the data through a custom function, and saving it to a top-scope variable in site.pp

#### trusted\_external\_command

The trusted\_external\_command feature allows a script to be run to query data from an external source, and make it available to Puppet in the `$trusted` variable. Specifically, data will be available under `trusted.external`.

Assuming that the full path to the data to use for `change_risk::permitted_risk` is `trusted.external.arbiter.permitted_risk`, set the following key in your Hiera data to configure change\_risk appropriately.

```yaml
change_risk::permitted_risk: "%{trusted.external.arbiter.permitted_risk}"
```

#### Top-scope Variables

A variable can be set in top-scope and used similarly to the way the built-in `$trusted` variable is. If an ENC supplies the top-scope variable, it may be used directly. If the variable will be assigned a value based on calling a Puppet function, it must be set and called in site.pp, before any resources or classes are evaluated.

```puppet
$arbiter = arbiter::fetch_data(getvar('trusted.certname'))
```

Assuming you have a top-scope variable called `$arbiter` and it contains a hash key `permitted_risk`, you can configure change\_risk to use it by setting a Hiera key as follows.

```yaml
change_risk::permitted_risk: "%{arbiter.permitted_risk}"
```

### Site.pp Example

The change\_risk class can be declared directly to supply the necessary configuration data. This is method of configuring change\_risk is recommended only for testing purposes.

```puppet
class { 'change_risk':
  $permitted_risk => {
    'high'    => false,
    'medium'  => true,
    'low'     => true,
    'unknown' => true,
  },
}
```

## Usage

The method by which configuration elements are disabled in this pattern is by being switched to no-op. The [trlinkin-noop](https://forge.puppet.com/trlinkin/noop) module is used to do this.

### Change Risk Class Function

At the top of a class, declare the change risk level using the `change_risk()` function. 

```puppet
class profile::postfix (
  # Various normal class parameters
  String         $alias_maps = 'hash:/etc/aliases',
  Optional[Hash] $configs    = {},
) {
  change_risk('low')

  # Normal configuration management code from this point forward
  contain postfix::ldap
  contain postfix::mta
  contain postfix::satellite

  file { '/tmp/not-important':
    ensure => file,
  }
}
```

### Change Risk Block

The `change_risk()` function can also be used as a block wrapper, to selectively mark and control risk evaluation levels for smaller, more granular collections of resources.

The following example shows how to implement the `change_risk()` function as a block, signaling that the resources inside the block are considered high-risk changes.

```puppet
change_risk('high') || {
  file { '/etc/postfix/main.cf':
    ensure  => file,
    replace => true,
    source  => 'puppet:///modules/postfix/main.cf',
  }

  service { 'postfix':
    ensure    => running,
    subscribe => File['/etc/postfix/main.cf'],
  }
}
```

Because of the potential for unexpected variable scope when using the `noop()` function in any Puppet code block, it is best to only put resource declarations inside these blocks. When possible, keep other Puppet code—include calls, complex logic, and so forth—outside of the risk evaluation block.

### No-op Class Interface

The [no-op class interface](https://forge.puppet.com/trlinkin/noop#class-interface) pattern can be used to provide a no-op switch at a class level. An advantage of providing this switch at a class level is that it can be overridden on a per-class basis using Hiera data parameters. If the appropriate supporting controls are in place, this can allow for on-demand switching on or off of specific classes for controlled Puppet runs.

The `change_risk()` function can be used in conjunction with the no-op class interface to allow developers to indicate the evaluated risk level of their class, but also respect a `$class_noop` parameter, if supplied to the class. That is, by default, `change_risk()` will also implement `noop::class_interface()`.

The following example shows how to implement the no-op class interface in conjunction with the `change_risk()` function.

```puppet
class profile::postfix (
  # Various normal class parameters
  String           $alias_maps = 'hash:/etc/aliases',
  Optional[Hash]   $configs    = {},

  # No-op class interface parameter.
  Optional[Boolean] $class_noop = undef,
) {
  change_risk('low')

  # Because $class_noop exists:
  #  - If $class_noop == true, change_risk() will invoke the noop() function
  #    for the class, even if the change would otherwise be permitted.
  #  - If $class_noop == false, change_risk() will NOT no-op the class, even
  #    if change would normally not be permitted.

  # Normal configuration management code from this point forward

  # ...
}
```

### In Combination

The change risk class function and block forms can be used together, if needed. The following example shows a class implemented with the `change_risk()` function called at the class level, but also containing a code block of resources with a different risk level specified.

The following example demonstrates using the class function call together with a nested change risk block.

```puppet
class profile::postfix (
  # Various normal class parameters
  String            $alias_maps = 'hash:/etc/aliases',
  Optional[Hash]    $configs    = {},
) {
  change_risk('low')

  # Normal configuration management code from this point forward
  contain postfix::ldap
  contain postfix::mta
  contain postfix::satellite

  # A block of high-risk changes
  change_risk('high') || {
    file { '/etc/postfix/main.cf':
      ensure  => file,
      replace => true,
      source  => 'puppet:///modules/postfix/main.cf',
    }

    service { 'postfix':
      ensure    => running,
      subscribe => File['/etc/postfix/main.cf'],
    }
  }

  # More normal configuration management code
  anchor { 'postfix::begin': }
  -> class { '::postfix::packages': }
  -> class { '::postfix::files': }
  ~> class { '::postfix::service': }
  -> anchor { 'postfix::end': }
}
```

## Operation

A normal Puppet agent run will use `change_risk::permitted_risk` information to automatically no-op classes and code blocks based on permitted risk. When performing manual Puppet agent runs, there are several mechanisms available to override the automatic no-op decisions.

### Hiera Data

If no-op class interface `$class_noop` parameters are being used, per-class hiera data may be set to override the main `change_risk()` check for any class so instrumented. Such an override will not, however, affect any nested change risk blocks inside the class.

To override the class no-op setting for profile::postfix and force it to run in op mode, set the following Hiera data parameter:

```yaml
profile::postfix::class_noop: false
```

### Command-line Flags

A manual Puppet run with the `--no-noop` flag passed will bypass all `change_risk()` checks, such that all classes using the no-op class interface will be enforced, and all Arbiter risk-evaluation code blocks will be enforced, regardless of Arbiter's assessed risk tolerance level.

The `--no-noop` flag is available when using the orchestrator to perform Puppet agent runs remotely.

```
puppet agent -t --no-noop
```

The `--no-noop` flag may be combined with the `--tags` flag for a limited ability to target specific change. Note that the usual limitations and characteristics of the `--tags` flag apply.

```
puppet agent -t --no-noop --tags profile::postfix
```

### Facter Facts

To support use cases where running Puppet with `--no-noop` is not feasible, change\_risk can be configured to ignore the command-line flag and consult the value of a special fact instead: `ignore_change_risk`. If so configured, and if the `ignore_change_risk` fact is set to `true` or `"true"`, then `change_risk()` function calls will ignore permitted risk and allow all configuration to be applied.

## Reference

### change\_risk Class

A change\_risk class provides a way to configure the behavior of `change_risk()` function calls.

### Change Risk Function

The `change_risk()` function is implemented in Ruby. For the block variant, it creates a new scope from the containing scope in which to evaluate code, and calls the `noop()` function in that scope if the risk permitted indicates that the code should be disabled. This means these code blocks are subject to the same variable scope consideration that always applies when using the `noop()` function.
