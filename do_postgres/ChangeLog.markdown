## 0.10.17 2016-01-24

* Fix memory leak
* Fix bug with DateTime and wrong timezone offsets  

## 0.10.16 2015-05-17

* Fix compile issue with do\_postgres on stock OS X Ruby

## 0.10.15 2015-02-15

* Ruby 2.2 support
* Double after free fix in do\_postgres
* Windows support on 2.1.x and 2.2.x

## 0.10.14 2014-02-13

* Don't do DNS lookup in transaction loading
* Set datestyle to ISO

## 0.10.13 2013-05-27

* Fix segfault on invalid API usage
* Windows binary for Ruby 2.0

## 0.10.12 2013-01-21

* jdbc-postgres driver loading fix

## 0.10.11 2012-12-29

* Rename C symbols to prevent name collitions

## 0.10.10 2012-10-11

No changes

## 0.10.9 2012-08-13

* Improved RETURNING handling on JRuby
* Allow for an empty database name

## 0.10.8 2012-02-10

* Ruby 1.9.3 compatibility on Windows
* Fix crash issue when reading a reader twice

## 0.10.7 2011-10-13

* Ruby 1.9.3 compatibility

## 0.10.6 2011-05-22

Bugfixes
* Fix an issue on some platforms when multiple DO drivers are loaded

## 0.10.5 2011-05-03

No changes

## 0.10.4 2011-04-28

New features
* Add save point to transactions (all)
* JRuby 1.9 mode support (encodings etc.)

Bugfixes
* Fix segfault when no tuples are returned from a non select statement (do\_postgres)
* Fix bug when using nested transactions in concurrent scenarios (all)
* Use column aliases instead of names (jruby)
* DST calculation fixes (all)
* Fix handling sub second precision for Time objects (do\_postgres)

Other
* Refactor to DRY up the adapters (all)
* Many style fixes
* Switch back to RSpec

## 0.10.3 2011-01-30
* Reworked transactions
* Fix a DST bug that could cause datetimes in the wrong timezone

## 0.10.2 2010-05-19
* Make Encoding.default_internal aware
* Rework logging for making callbacks possible
* Remove handling Object types directly

## 0.10.1 2010-01-08

* Support for Ruby 1.8 and 1.9 on Windows.
* Switch to Jeweler for Gem building tasks (this change may be temporary).
* Switch to using Bacon for running specs: This should make specs friendlier to
  new Ruby implementations that are not yet 100% MRI-compatible, and in turn,
  pave the road for our own IronRuby and MacRuby support.
* Switch to the newly added rake-compiler `JavaExtensionTask` for compiling
  JRuby extensions, instead of our (broken) home-grown solution.

## 0.9.12 2009-05-17
* Improvements
  * Windows support

## 0.9.11 2009-01-19
* Improvements
  * Ruby 1.9 support
* Fixes
  * Fix build issue on certain platforms introduces with 0.9.10

## 0.9.9 2008-11-27
* No changes since 0.9.8
