## 0.10.2 2010-05-19
* No changes

## 0.10.1 2010-01-08

Initial release as part of mainline DataObjects project.

* Switch to Jeweler for Gem building tasks (this change may be temporary).
* Switch to using Bacon for running specs: This should make specs friendlier to
  new Ruby implementations that are not yet 100% MRI-compatible, and in turn,
  pave the road for our own IronRuby and MacRuby support.
* Switch to the newly added rake-compiler `JavaExtensionTask` for compiling
  JRuby extensions, instead of our (broken) home-grown solution.

* Known Issues:
  * Writing Extlib::ByteArray is not currently supported.

## 0.10.0 2009-09-15

(NOT RELEASED)

* Improvements
  * JRuby Support (using *do_jdbc*)

## 0.0.1 2009-05-11

* 1 major enhancement:
  * Initial release
