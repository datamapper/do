do\_jdbc 'Doppio'
=========================

*Native JDBC Support for DataObjects*

**WARNING** This package is under heavy development. 

Test
----

the default task:
	jruby -S rake
or:
	jruby -S rake java_compile
	jruby -S rake spec

Installation
------------

Install Data Objects 0.9.9 from Git sources:

	jruby -S gem install pkg/data_objects-0.9.9.gem
or

    rake jruby:install


then build, test Doppio:

 	jruby -S rake java_compile
	jruby -S rake package
	jruby -S gem install pkg/do_jdbc-0.9.9.gem

Licensing and Copyright
-----------------------

This code is licensed under the **GNU Public License (GPL) v2**, and under an
**MIT License**. Please see GPL-LICENSE and MIT-LICENSE for the text of those
license documents.

Copyright (c) 2008-2009 Alexander Coles, Ikonoklastik Productions

Support
-------

This Module is under heavy development. No official support is currently 
provided.

* Contact the developer directly:
   - <alex@alexcolesportfolio.com> | myabc on #datamapper, #merb IRC