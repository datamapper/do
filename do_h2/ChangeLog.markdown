## 0.10.3 2011-01-30
* No changes

## 0.10.2 2010-05-19
* No changes

## 0.10.1 2010-01-08

* Switch to Jeweler for Gem building tasks (this change may be temporary).
* Switch to using Bacon for running specs: This should make specs friendlier to
  new Ruby implementations that are not yet 100% MRI-compatible, and in turn,
  pave the road for our own IronRuby and MacRuby support.
* Switch to the newly added rake-compiler `JavaExtensionTask` for compiling
  JRuby extensions, instead of our (broken) home-grown solution.

## 0.10.0 2009-09-15

Initial release of H2 driver (using *do_jdbc*).

* Known Issues
  * JRuby-only
