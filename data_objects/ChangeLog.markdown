## 0.10.10 2012-10-11

* JRuby performance improvements
* Reconnect added on JRuby
* do\_sqlite3 C driver supports busy\_timeout

## 0.10.9 2012-08-13

* Don't try to escape queries when no binding parameters are given

## 0.10.8 2012-02-10

* Ruby 1.9.3 compatibility on Windows
* Don't display password in URI

## 0.10.7 2011-10-13

* Ruby 1.9.3 compatibility

## 0.10.6 2011-05-22

Bugfixes
* Fix an issue on some platforms when multiple DO drivers are loaded

## 0.10.5 2011-05-03

Bugfixes
* Fix an issue with DateTime (do\_sqlite3)

## 0.10.4 2011-04-28

New features
* Add save point to transactions (all)
* JRuby 1.9 mode support (encodings etc.)

Bugfixes
* Fix segfault when no tuples are returned from a non select statement (do\_postgres)
* Fix bug when using nested transactions in concurrent scenarios (all)
* Use column aliases instead of names (jruby)
* DST calculation fixes (all)
* Attempt to add better support for ancient MySQL versions (do\_mysql)
* Fix handling sub second precision for Time objects (do\_postgres)

Other
* Refactor to DRY up the adapters (all)
* Many style fixes
* Switch back to RSpec

## 0.10.3 2011-01-30
* Reworked transactions
* Fix a DST bug that could cause datetimes in the wrong timezone

## 0.10.2 2010-05-19
* Support for Encoding.default_internal
* Rework logging to adding a callback is possible

## 0.10.1 2010-01-08

* Removal of Extlib dependency: Pooling and Utilities code moved to DataObjects.
* Switch to Jeweler for Gem building tasks (this change may be temporary).
* Switch to using Bacon for running specs: This should make specs friendlier to
  new Ruby implementations that are not yet 100% MRI-compatible, and in turn,
  pave the road for our own IronRuby and MacRuby support.
* Make DataObjects::Reader Enumerable.

## 0.10.0 2009-09-15

* No Changes since 0.9.11

## 0.9.11 2009-01-19
* Fixes
  * Use Extlib `Object.full_const_get` instead of custom code
  * Remove Field as it was unused

## 0.9.9 2008-11-27
* No Changes since 0.9.8
