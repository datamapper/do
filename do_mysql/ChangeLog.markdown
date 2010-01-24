## 0.10.2 (unreleased, in git)

## 0.10.1 2010-01-08

* Support for Ruby 1.8 and 1.9 on Windows.
* Switch to Jeweler for Gem building tasks (this change may be temporary).
* Switch to using Bacon for running specs: This should make specs friendlier to
  new Ruby implementations that are not yet 100% MRI-compatible, and in turn,
  pave the road for our own IronRuby and MacRuby support.
* Switch to the newly added rake-compiler `JavaExtensionTask` for compiling
  JRuby extensions, instead of our (broken) home-grown solution.

## 0.10.0 2009-09-15
* Improvements
  * JRuby Support (using *do_jdbc*)

## 0.9.12 2009-05-17
* Improvements
  * Windows support

## 0.9.11 2009-01-19
* Improvements
  * Ruby 1.9 support
* Fixes
  * Reconnecting now works properly

## 0.9.9 2008-11-27
* Improvements
  * Added initial support for Ruby 1.9 [John Harrison]
