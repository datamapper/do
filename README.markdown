Doppio
======

*Native JDBC Drivers for DataObjects*

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

Install Data Objects 0.9.0 from Git sources:

	jruby -S gem install pkg/data_objects-0.9.0.gem

then build, test Doppio:

 	jruby -S rake java_compile
	jruby -S rake package
	jruby -S gem install pkg/doppio-0.9.0.gem

