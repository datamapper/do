## 0.10.1 (unreleased, in git)

* Removal of Extlib dependency: Pooling and Utilities code moved to DataObjects.
* Switch to Jeweler for Gem building tasks (this change may be temporary).
* Switch to using Bacon for running specs: This should make specs friendlier to
  new Ruby implementations that are not yet 100% MRI-compatible, and in turn,
  prepared the road for our own IronRuby and MacRuby support.
* Make DataObjects::Reader Enumerable.

## 0.10.0 2009-09-15

* No Changes since 0.9.11

## 0.9.11 2009-01-19
* Fixes
  * Use Extlib `Object.full_const_get` instead of custom code
  * Remove Field as it was unused

## 0.9.9 2008-11-27
* No Changes since 0.9.8
