# Change Risk

## Description

Let "Arbiter" be a service that provides change risk assessment information for a given node at the current time. Further, let Arbiter be assumed to consider information from ServiceNow—node ownership, escalation status, maintenance window, peak business hours, other data points—and produce a simple matrix of change risk-to-permitted decisions. Low-risk change: permitted. Medium-risk change: not permitted. And so forth.

This module provides Puppet code patterns and constructs that let developers declare their code with change risk information. The constructs will allow Puppet to selectively and automatically tag and/or no-op configuration elements according to the current change risk tolerance permitted by Arbiter.

## Usage

### Configure permissible change risks

For testing or semi-permanent configuration, this can just be done in Hiera yaml.

```yaml
change_risk::permitted_risk:
  high:    false,
  medium:  true,
  low:     true,
  unknown: true,
```

_See [setup](#setup) for more ways to to source this information._

### Use `change_risk()` in code

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

### Run Puppet

When Puppet evaluates a `change_risk()` class or block, it will tag all contained resources with a "change\_risk:\<risk\>" tag. It will then check to see if the specified change risk is permissible. If the risk is permissible, Puppet will proceed. If the risk is _not_ permissible, Puppet will set all contained resources to no-op.

### Use change-risk information in reporting

PQL queries can return information about resources in node catalogs and their assessed change-risk levels. Resources will have been tagged with a tag of the form "change\_risk:\<risk\>". E.g. "change\_risk:high" or "change\_risk:low".

```shell
puppet query 'resources { certname = "my-node" and tags = "change_risk:high" }'
```

## Cautions

### Scope considerations

The `change_risk()` function relies on the [trlinkin-noop](https://forge.puppet.com/trlinkin/noop) module to implement its no-op directives when a change risk is not permitted. When using `change_risk()`, or indeed any variant of trlinkin-noop's `noop()` function, the following "rule-of-thumb" best practices should be applied.

1. Don't call `change_risk()` inside a profile class unless you are using the block-form.
2. Inside `change_risk()` classes or blocks, <u>strongly</u> prefer resource-style class delcaration over `include()`.
3. Don't declare "includable" classes (classes you expect to be included from multiple other places in code) inside a `change_risk()` class or block.

_**Note:** for the purpose of these cautions, let `include()` refer equally to ANY of_

* _`include()`_
* _`require()`_
* _`contain()`_

#### Explanation

The root consideration that all of these cautions are drawn from is the behavior of Puppet's [scoping](https://puppet.com/docs/puppet/latest/lang_scope.html). Specifically, Puppet's [dynamic scoping](https://puppet.com/docs/puppet/latest/lang_scope.html#dynamic-scope), and how it affects class declaration. This is because the functional effects of `noop()` and the tagging effects of `change_risk()` propogate from parent scopes downwards into child scopes. 

From the docs:

> * The parent of \[most classes or resources\] is the _**first scope**_ \[emphasis added\] in which \[the class or resource\] was declared
> * Because classes can be declared multiple times with the include function, the contents of a given scope are evaluation-order dependent

What this means, in short, is that a class `include()`'d inside a `change_risk()` block is subject to that block's no-op capability IF AND ONLY IF it has not already been `include()`'d somewhere else in Puppet code.

Detailed breakdown for each rule-of-thumb element follows.

1. _Don't call `change_risk()` inside a profile class unless you are using the block-form._  
   **Reasoning:** Profile classes are designed to be "includable", meaning it is expected that profiles should be safe to include from other profiles, potentially many times. Further, profile classes are expected to freely include other profiles. Because of this, the first place a profile class is included from is considered indeterminate and cannot be guaranteed. To avoid non-deterministic application of change-risk tagging, don't call the `change_risk()` class function directly inside a profile. Be more judicious and use the block form of `change_risk()` in profiles instead, and avoid using `include()` inside `change_risk()` blocks.
2. _Inside `change_risk()` classes or blocks, <u>strongly</u> prefer resource-style class delcaration over `include()`._  
    **Reasoning:** Resource-style class declaration has a desirable side-effect when we care deeply about what a class's parent scope will be: if the class's parent scope won't be the scope we declare it in (because it has been included somewhere else already), Puppet will raise a duplicate resource declaration error and fail the catalog. To help ensure deterministic scoping results for code inside `change_risk()` blocks, use resource-style class declaration whenever you can instead of `include()`, `require()` or `contain()`. Note that for contain specifically, it is safe to call `contain()` for a class right after declaring it, if you also need contain's special containment semantics to be applied.
3. _Don't declare "includable" classes (classes you expect to be included from multiple other places in code) inside a `change_risk()` class or block._  
    **Reasoning:** as a corollary to the above point, if you would like to be able to `include()` a class elsewhere, you shouldn't declare it resource-style in your `change_risk()` block. If you find yourself at an impass struggling to adhere to rule-of-thumb points both 1 and 2 because they seem in conflict, it may be advisable to refactor your code—perhaps by creating a new, includable profile, which itself _can_ safely declare the class in question resource-style, in its own internal `change_risk()` block, after which the new profile can be included elsewhere.
    
### No-op and dependencies

Be aware that if resource **A** is a dependency of resource **B** and **A** is no-op, Puppet will _always_ consider **B**'s dependency to be satisfied, even if resource **A** is detected to be out-of-sync. Because resource **A** is in no-op mode it cannot "fail", and so Puppet will never skip resource **B** due to a dependency failure.

Depending on your dependency chains this could cause problems, when, for example, Puppet cannot actually successfully configure resource **B** unless or until resource **A** is in-sync.

## Setup

The behavior of the `change_risk()` function is controlled through a configuration class. The configuration can be set by providing the appropriate settings using Hiera data (preferred), or by declaring the class resource-style in site.pp (only recommended for testing purposes).

The `$permitted_risk` configuration parameter could be set statically in a Hiera yaml file, or it could be supplied dynamically using either a Puppet function call to query a service such as Arbiter, or by querying Arbiter data using a `trusted_external_command` integration.

### Hiera data

In the example below the risk tolerance data shown is static, and does not change unless the Hiera yaml file changes, or some condition causes Hiera to consult a different file.

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

Note that the only required parameter is `change_risk::permitted_risk`. The remaining parameters have acceptable defaults. For more information on each of these parameters and what they affect, see the [reference](#change_risk_class) section.

### External data sources

If change risk data is coming from a system like Arbiter, it can be consumed in Puppet either by:

* Using the `trusted_external_command` feature
* Supplying the data through an ENC, as a top-scope variable
* Supplying the data through a custom function, and saving it to a top-scope variable in site.pp

#### trusted\_external\_command

The trusted\_external\_command feature allows a script to be run to query data from an external source, and make it available to Puppet in the `$trusted` variable. Specifically, data will be available under `trusted.external`.

Assuming that the full path to the data to use for `change_risk::permitted_risk` is `trusted.external.arbiter.permitted_risk`, set the following key in your Hiera data to configure `change_risk()` appropriately.

```yaml
change_risk::permitted_risk: "%{trusted.external.arbiter.permitted_risk}"
```

#### Top-scope variable

A variable can be set in top-scope and used similarly to the way the built-in `$trusted` variable can be.

Suppose this variable is called `$arbiter`, and is a hash with a `permitted_risk` key. If an ENC supplies `$arbiter`, it may be referenced directly in Hiera without additional work.

```yaml
change_risk::permitted_risk: "%{arbiter.permitted_risk}"
```

If the variable will be assigned a value based on calling a Puppet function, it must be set and called in site.pp, before any resources or classes are evaluated.

```puppet
# site.pp
$arbiter = arbiter::fetch_data(getvar('trusted.certname'))
```

Once the variable is assigned a value in site.pp, it can be referenced in Hiera the same way an ENC-provided variable would be.

### Site.pp

The change\_risk class can be declared directly to supply the necessary configuration data. This is method of configuring change\_risk is recommended only for testing purposes.

```puppet
# site.pp
class { 'change_risk':
  $permitted_risk => {
    'high'    => false,
    'medium'  => true,
    'low'     => true,
    'unknown' => true,
  },
}
```

## Operation

A normal Puppet agent run will use `change_risk::permitted_risk` information to automatically no-op classes and code blocks based on permitted risk. When performing manual Puppet agent runs, there are several mechanisms available to override the automatic no-op decisions.

### Command-line Flags

`change_risk()` can be configured to ignore permissible change risks and allow all changes when the `--no-noop` flag is passed to Puppet on the command line.

```
puppet agent -t --no-noop
```

The `--no-noop` flag may be combined with the `--tags` flag for a limited ability to target specific change. Note that the usual limitations and characteristics of the `--tags` flag apply.

```
puppet agent -t --no-noop --tags profile::postfix
```

The `--no-noop` flag is available when using the orchestrator to perform Puppet agent runs remotely.

The `--no-noop` flag can be used to disable permissible change checks when [`change_risk::disable_mechanism`](#disable_mechanism) is set to "flag" or to "both".

### Facter Facts

`change_risk()` can be configured to consult the value of a special fact to decide whether or not to respect permissible change risks: `ignore_permitted_risk`. If this fact is set to Boolean true or the string "true", then `change_risk()` will ignore permissible change risks and allow all change.

Note that besides using a custom fact in the facts.d directory, facts can be set when running Puppet on the command line using environment variables. For example, to run Puppet once with `ignore_permitted_risk=true`, the following command can be used.

```shell
FACTER_ignore_permitted_risk=true puppet agent -t
```

The `ignore_permitted_risk` Facter fact can be used to disable permissible change checks when [`change_risk::disable_mechanism`](#disable_mechanism) is set to "fact" or to "both".

### Hiera Data

If the `change_risk::ignore_permitted_risk` class parameter is set to `true` (either through class declaration or through Hiera data) then `change_risk()` will ignore permissible change risks and allow all change.

```yaml
change_risk::ignore_permitted_risk: true
```

If no-op class interface `$class_noop` parameters are being used, per-class hiera data may be set to override the main `change_risk()` check for any class so instrumented. Such an override will not, however, affect any nested change risk blocks inside the class.

To override the class no-op setting for profile::postfix and force it to run in op mode, set the following Hiera data parameter:

```yaml
profile::postfix::class_noop: false
```

The noop class interface mechanism can be used on classes which support it when [`change_risk::respect_noop_class_interface`](#respect_noop_class_interface) is set to true (default).

## Examples

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
  
  # ...

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

### No-op Class Interface

The method by which configuration elements are disabled in this pattern is by being switched to no-op. The [trlinkin-noop](https://forge.puppet.com/trlinkin/noop) module is used to do this.

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

## Reference

### change\_risk Class

The change\_risk class provides a way to configure the behavior of `change_risk()` function calls.

#### permitted\_risk

A hash of change risk values ("low", "medium", "high", etc.) to Booleans. True indicates the change risk is permissible, while false indicates the change risk is not permissible, and any resources marked with that change risk should be no-op'd.

Example:

```puppet
{
  'low'    => true,
  'medium' => false,
  'high'   => false,
}
```

To support Hiera references to other variables, this parameter will also accept a String representation of a Puppet language Hash[String, Boolean].

#### risk\_not\_found\_action

Accepts one of the following values. These values define what Puppet will do if a `change_risk()` function call is evaluated which uses a risk that is not present in the permitted\_risk hash.

* `fail` – Fail the catalog
* `none` – Don't no-op the resources in the block
* `noop` – No-op the resources in the block 

#### ignore\_permitted\_risk

When set to `true`, this effectively disables the ability for `change_risk()` to no-op resources. Defaults to `false`.

#### disable\_mechanism

Defines how to temporarily disable the ability for `change_risk()` to no-op resources. There are two possible configurations to disable `change_risk()` no-op behavior.

* `flag` – Use the `--no-noop` flag on the command line
* `fact` – Use `facts.ignore_permitted_risk=true` 
* `both` – Use EITHER the `--no-noop` flag OR the value of `facts.ignore_permitted_risk`

#### respect\_noop\_class\_interface

This enables or disables compatability with trlinkin-noop's `noop::class_interface()` pattern. If set to `true` (default), then class parameters `$class_noop` and `$class_noop_override` can be used for individual classes which call `change_risk()` internally, and those parameters will take precedence over `change_risk()`'s determination of whether or not to no-op the class based on permitted risk.

Setting `$class_noop` to True or False will switch over to `noop::class_interface()`'s semantics. Leave `$class_noop` undefined, or don't provide it on a class, to leave `change_risk()`'s semantics in effect.

* `true` – Respect the values of `$class_noop` or `$class_noop_override`, if present
* `false` – Ignore the values of `$class_noop` and `$class_noop_override`

### Change Risk Function

The `change_risk()` function is implemented in Ruby. For the block variant, it creates a new scope from the containing scope in which to evaluate code, and calls the `noop()` function in that scope if the risk permitted indicates that the code should be disabled. This means these code blocks are subject to the same variable scope consideration that always applies when using the `noop()` function.
