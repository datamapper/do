## 0.10.1 (unreleased, in git)

* Switch to Jeweler for Gem building tasks (this change may be temporary).
* Switch to using Bacon for running specs: This should make specs friendlier to
  new Ruby implementations that are not yet 100% MRI-compatible, and in turn,
  prepared the road for our own IronRuby, Rubinius and MacRuby support.
* Switch to the newly added rake-compiler `JavaExtensionTask` for compiling
  JRuby extensions, instead of our (broken) home-grown solution.

## 0.10.0 2009-09-15

Initial release of Derby driver (using *do_jdbc*).

* Known Issues
  * JRuby-only
