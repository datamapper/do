## 0.10.2 2010-05-19
* Remove Object handling

## 0.10.1 2010-01-08

* Switch to Jeweler for Gem building tasks (this change may be temporary).
* Switch to the newly added rake-compiler `JavaExtensionTask` for compiling
  JRuby extensions, instead of our (broken) home-grown solution.

### Changes (in detail)

 * Use recursive RubyType#getRubyType for inference (Alex Coles) (commit 046c703)
 * Revert "Added support for subclasses of supported types" (Alex Coles) (commit 8e64ca1)
 * fixed situation where types for reader are a subclass of one the allowed types. added spec. (mkristian) (commit 67e3ef9)
 * Added support for subclasses of supported types (Piotr Gega (pietia)) (commit 59923d1)
 * Removed unnecessary wildcard boundation (Piotr Gega (pietia)) (commit 880c823)
 * Closed resources that were not being closed when exceptional situations occures (Piotr Gega (pietia)) (commit da06fe8)
 * Added helper method for closing both RS and ST object in one method (Piotr Gega (pietia)) (commit b43708f)
 * StringUtil prevented from instantiating (Piotr Gega (pietia)) (commit 016ed27)
 * Changed StringBuffer to StringBuilder where synchronization is not needed (Piotr Gega (pietia)) (commit 78cbc98)
 * Closed not closed PS object (Closing moved to Reader) (Piotr Gega (pietia)) (commit 604218e)
 * Updated Maven's configuration files (Piotr Gega (pietia)) (commit 137efd5)
 * Added maven-pmd-plugin to pom.xml (Piotr Gega (pietia)) (commit bdd96e4)
 * Revert "Always downcase field names" (Alex Coles) (commit 94c5936)
 * return false on close if the Reader is already closed (mkristian) (commit ded1f9a)
 * Remove merge conflict artefacts (Alex Coles) (commit 4e6efca)
 * more optimisations:  * setting array/list size where possible  * avoiding object creation  * precompute TRUE,FALSE,NIL and reuse them  * switched one more ivar to java instance variable  * replace getter/setter with direct field invocation  * removed some precondition check and merge two methods (mkristian) (commit 0336dc3)
 * Fix broken logic for type inference in Command (Alex Coles) (commit 8617aae)
 * Refactoring to use Java fields not ivars (Alex Coles) (commit cfe59f4)
 * Removed deprecated code (i.e. java.sql.Date#getHours()) (Piotr Gęga (pietia)) (commit ee4f9e0)
 * Removed ability to instantiate DataObjects (Piotr Gęga (pietia)) (commit 8b91539)
 * extracted JDBC URI generation as driver getJdbcUri method which is overridden for Oracle driver (Raimonds Simanovskis) (commit 3f32c3b)
 * Add comment - RS.close() not needed (Piotr Gęga (pietia)) (commit 56d9a75)
 * Code cleanups (Unused imports,unused ++, Forgot @param) (Piotr Gęga (pietia)) (commit 8861643)
 * Close UnmarshalStream object (Piotr Gega (pietia)) (commit 90a59c2)
 * Javadoc starter step (Piotr Gega (pietia)) (commit 1204f7d)
 * Removed Javadoc @params for non-existent methods' parameters (Piotr Gega (pietia)) (commit 7b4560f)
 * Fix Typo(Unneeded invocation on object that may be a null) (Piotr Gega (pietia)) (commit 9f45f88)
 * Extlib Removal: Object to DO#full_const_get (Alex Coles) (commit 8cc2da4)
 * Fix missed usage of ivar in Transaction (Alex Coles) (commit 847263f)
 * Always downcase field names (Alex Coles) (commit 060e778)
 * Fix for JRuby 1.4RCx: ivars/Java objects (Alex Coles) (commit 34a091e)
 * Fix unquoted path in Rake compile task (Alex Coles) (commit 176926b)
 * Remove unwanted cast (Alex Coles) (commit 3fa36c0)
 * Teach To The Test: JRuby/MRI Fixnums (Alex Coles) (commit 677211f)
 * Fix for large Bignum args (Alex Coles) (commit 37c95cd)
 * Handle user/password defaults (Alex Coles) (commit ea9109d)
 * Fix path handling when connecting with a URI (Peter Brant) (commit 2d7b1ae)

## 0.10.0 2009-09-15

First release of DataObjects' comprehensive support for JRuby that should be
suitable for widespread testing.

Please also read the accompanying release notes for individual drivers.

### Changes

  * Since the test gem was released, substantial work has been done to
  . Parti to Raimonds Simanovskis
    (rsim) and Kristian Meier (mkristian) for substantial patches.

### Known Issues

  * Error
  * URI parsing
  * Reports
  * Connection via JNDI is not yet fully implemented.
  * Problem with PATH syntax compiling on Windows with JRuby.
  http://sources.redhat.com/ml/kawa/2000/msg00311.html

## 0.9.12 2009-05-17

* Initial testing version released
