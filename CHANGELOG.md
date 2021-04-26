# Changelog

All notable changes to this project will be documented in this file.

## Release 0.2.0

**Features**

* Added support for oscillating between different risk levels inside nested scopes

**Improvements**

* Added debug statements to change\_risk function

**Bugfixes**

* Fixed a `puppet apply` problem around trusted facts
* Fixed a dependency documentation issue; change\_risk requires Puppet 6.4.5 or newer
* Fixed a bug in the block form of change\_risk() which caused no-op not to be enforced

## Release 0.1.4

**Bugfixes**

* Fixed issue where variables defined but set to undef became out of scope inside a change\_risk function block

## Release 0.1.3

**Bugfixes**

* Fixed issue where variables were out of scope inside a change\_risk function block

## Release 0.1.0

**Features**

**Bugfixes**

**Known Issues**
