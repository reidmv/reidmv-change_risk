# Pocketwatch

## Description

Pocketwach is a service that provides change risk assessment information for a given node at the current time. Pocketwatch considers information from ServiceNow—node ownership, escalation status, maintenance window, peak business hours, other data points—and produces a simple matrix of risk-evaluation to change-permitted decisions. Low-risk change: permitted. Medium-risk change: not permitted. And so forth.

This module provides Puppet code patterns and constructs that let developers declare their code with risk evaluation information. When used, the constructs will allow a Puppet run to selectively and automatically enable or disable configuration elements according to the current risk tolerance permitted by Pocketwatch.

## Usage in Code

The method by which configuration elements are disabled in this pattern is by being switched to no-op. The [trlinkin-noop](https://forge.puppet.com/trlinkin/noop) module is used to do this.

### No-op Class Interface

The [no-op class interface](https://forge.puppet.com/trlinkin/noop#class-interface) pattern can be used to provide a no-op switch at a class level. An advantage of providing this switch at a class level is that it can be overridden on a per-class basis using Hiera data parameters. If the appropriate supporting controls are in place, this can allow for on-demand switching on or off of specific classes for controlled Puppet runs.

The Pocketwatch risk-evaluation function can be used in conjunction with the no-op class interface to allow developers to indicate the evaluated risk level of their class, so that Pocketwatch can automatically enforce or disable the class during a Puppet run depending on the permitted change risk levels.

The following example shows how to implement the no-op class interface in conjunction with the Pocketwatch risk-evaluation function.

```puppet
class profile::postfix (
  # Various normal class parameters
  String           $alias_maps      = 'hash:/etc/aliases',
  Optional[Hash]   $configs         = {},
  String           $inet_interfaces = 'all',
  String           $inet_protocols  = 'all',
  Boolean          $ldap            = false,
  Optional[String] $ldap_base       = undef,
  Optional[String] $ldap_host       = undef,

  # Required no-op class interface parameter, and pocketwatch risk evaluation.
  # In this case, the developer is indicating that the evaluated risk for changes
  # this class makes is "low".
  Boolean $class_noop = pocketwatch::risk_evaluation('low'),
) {
  # Required top-of-class function call implements no-op class interface
  noop::class_interface()

  # Normal configuration management code from this point forward
  anchor { 'postfix::begin': }
  -> class { '::postfix::packages': }
  -> class { '::postfix::files': }
  ~> class { '::postfix::service': }
  -> anchor { 'postfix::end': }

  # ...

}
```

### Risk Evaluation block

The Pocketwatch risk-evaluation function can also be used as a block wrapper, to selectively mark and control risk evaluation levels for smaller, more granular collections of resources.

The following example shows how to implement the Pocketwatch risk-evaluation function as a block, signaling that the resources inside the block are considered high-risk changes.

```puppet
pocketwatch::risk_evaluation('high') || {
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

Because of the potential corner cases involved when using the `noop()` function in any Puppet code block, it is best to only put resource declarations inside these blocks. When possible, keep other Puppet code—include calls, complex logic, and so forth—outside of the risk evaluation block.

### In Combination

The no-op class interface and Pocketwatch risk-evaluation block forms can be used together, if needed. The following example shows a class implemented with the no-op class interface at one risk level, but containing a code block of resources that are evaluated to have a different risk level.

When using the two patterns together it is recommended that nested blocks should only ever _raise_ the risk level. A low-risk class may contain some high-risk changes. The reverse risk relation is not supported.

The following example demonstrates using the no-op class interface together with a Pocketwatch risk-evaluation block.

```puppet
class profile::postfix (
  # Various normal class parameters
  String           $alias_maps      = 'hash:/etc/aliases',
  Optional[Hash]   $configs         = {},

  # Required no-op class interface parameter, and pocketwatch risk evaluation.
  Boolean $class_noop = pocketwatch::risk_evaluation('low'),
) {
  # Required top-of-class function call implements no-op class interface
  noop::class_interface()

  # Normal configuration management code from this point forward
  contain postfix::ldap
  contain postfix::mta
  contain postfix::satellite

  # A block of high-risk changes
  pocketwatch::risk_evaluation('high') || {
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

A normal Puppet agent run will use Pocketwatch information to automatically no-op classes and code blocks based on permitted risk. When performing manual Puppet agent runs, there are several mechanisms available to override the automatic no-op decisions.

### Hiera Data

Per-class hiera parameters may be set to override the main pocketwatch check for any class which uses `noop::class_interface()`. Such an override will not, however, affect any protected blocks inside the class. To override the class no-op setting for profile::postfix, set the following Hiera data parameter:

```yaml
profile::postfix::class_noop: false
```

### Command-line Flags


A manual Puppet run with the `--no-noop` flag passed will bypass all pocketwatch checks, such that all classes using the no-op class interface will be enforced, and all Pocketwatch risk-evaluation code blocks will be enforced, regardless of Pocketwatch's assessed risk tolerance level.

The `--no-noop` flag is available when using the orchestrator to perform Puppet agent runs remotely.

```
puppet agent -t --no-noop
```

The `--no-noop` flag may be combined with the `--tags` flag for a limited ability to target specific change. Note that the usual limitations and characteristics of the `--tags` flag apply.

```
puppet agent -t --no-noop --tags profile::postfix
```

## Reference

### Pocketwatch class

A pocketwatch class provides a way to query and save the risk assessment status during a Puppet run. The $pocketwatch::data variable, once pocketwatch has been included, makes this information available for Puppet to use in configuration management decision making. The pocketwatch class is included automatically whenever the `pocketwatch::risk_evaluation()` function is used.

Sample data:

```puppet
$data = {
  'risk-permitted' => {
    'high'    => false,
    'medium'  => false,
    'low'     => true,
    'unknown' => false,
  }
}
```

This data can be accessed using e.g.

```puppet
include pocketwatch

$high_risk_permitted = getvar('pocketwatch::data.risk-permitted.high')
```

### Pocketwatch Data Lookup Function

The pocketwatch class retrieves risk-evaluation information from Pocketwatch by calling `pocketwatch::lookup()` with a node's certname. The implementation of this function is TBD.

OR

Pocketwatch risk-evaluation information is presented to Puppet using the `trusted_external_command` interface. The pocketwatch class consults `trusted.external.pocketwatch` for this data, and sets its internal `$data` variable with the appropriate format to be consumed by the `pocketwatch::risk_evaluation()` function.

### Risk Evaluation Function

The `pocketwatch::risk_evaluation()` is implemented in Ruby. For the block variant, it creates a new scope from the containing scope in which to evaluate code, and calls the `noop()` function in that scope if the Pocketwatch risk evaluation indicates that the code should be disabled. This means these code blocks are subject to the same caveats, constraints, and considerations that always apply when using the `noop()` function.
