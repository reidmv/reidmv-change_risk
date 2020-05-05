# Change Risk

## Description

Let "Arbiter" be a service that provides change risk assessment information for a given node at the current time. Further, let Arbiter be assumed to consider information from ServiceNow—node ownership, escalation status, maintenance window, peak business hours, other data points—and produce a simple matrix of change risk-to-permitted decisions. Low-risk change: permitted. Medium-risk change: not permitted. And so forth.

This module provides Puppet code patterns and constructs that let developers declare their code with change risk information. The constructs will allow Puppet to selectively and automatically tag and/or no-op configuration elements according to the current change risk tolerance permitted by Arbiter.

## Configuration

The behavior of change\_risk code constructs is controlled through a configuration class. The configuration can be set by declaring the class resource-style in site.pp, or by configuring it via Hiera.

In the examples below the risk tolerance data shown is static. In a real-world scenario, the `$risk_permitted` configuration parameter could be supplied dynamically using either a Puppet function call to query a service such as Arbiter, or by querying Arbiter data using a `trusted_external_command` integration.

*site.pp:*

```puppet
class { 'change_risk':
  # The matrix of risk levels that have been defined, and whether or not
  # changes of that risk level are permitted
  $risk_permitted => {
    'high'    => false,
    'medium'  => true,
    'low'     => true,
    'unknown' => true,
  },

  # Default. options include: fail, op, noop
  not_found_behavior    => 'fail',

  # Default. whether or not to no-op affected resources if risk is not
  # permitted
  noop_unless_permitted => true,

  # Default. whether or not to tag resources with their change risk
  tag_change_risk       => true,

  # Default. whether or not to honor a $class_noop parameter
  implement_class_noop  => true,

  # Default. How to disable change_risk() checks for on-demand runs. Valid
  # values include: flag, fact, both
  disable_mechanism     => 'flag',
}
```

*hiera data:*

```yaml
change_risk::risk_permitted:
  high:    false,
  medium:  true,
  low:     true,
  unknown: true,

change_risk::not_found_behavior: fail
change_risk::noop_unless_permitted: true
change_risk::tag_change_risk: true
change_risk::implement_class_noop: true
```

If change risk data is coming from Arbiter via `trusted_external_command`, the `$risk_permitted` parameter might be set in Hiera as follows.

```yaml
change_risk::risk_permitted: "%{trusted.external.arbiter.risk_permitted}"
```

## Usage in Code

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

### Risk Evaluation block


### In Combination

The change risk class function and block forms can be used together, if needed. The following example shows a class implemented with the `change_risk()` function called at the class level, but also containing a code block of resources with a different risk level specified.

When using the two patterns together it is recommended that nested blocks should only ever _raise_ the risk level. A low-risk class may contain some high-risk changes. The reverse risk relation is not supported.

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

A normal Puppet agent run will use `change_risk::change_permitted` information to automatically no-op classes and code blocks based on permitted risk. When performing manual Puppet agent runs, there are several mechanisms available to override the automatic no-op decisions.

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
