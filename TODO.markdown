DataObjects TODO
==================

This is a semistructured document describing what the future plans
are for DataObjects. The list is ordered somewhat by priority.

Use native parameter binding
----------------------------

DataObjects should use native parameter binding available in the underlying
C drivers. This does mean that we should decide on the external facing API
and what type of parameter binding we support.

Initially we should use the ? anonymous binding syntax. This needs to translated
for Postgres into $1, $2 style binding. This should be done by a very simple
parse in C so it's fast, but it should be smart enough to handle ? in quoted strings etc.

The shared specs should be extended with cases testing the behavior with strings
that contain ? and other characters that can be significant.

Creating a shared library for common C code
-------------------------------------------

There is currently quite a bit of code duplication between the different drivers. We
should create a shared library that makes it possible to share this code between adapters.
This would for example include the parameter binding parser and the Date / Time and DateTime
parsing.

Expose non-blocking API in Ruby
-------------------------------
The drivers already use the non-blocking C api under the hood so the entire Ruby VM
doesn't stall when a query is executing. This non-blocking API should also be directly
available in Ruby. We should design an API for it with the according specs.

Prepared statements
-------------------
DataObjects should provide an API that allows a user to use prepared statements that can
be executed again with different parameters. This work probably depends on native parameter
binding being completed first.

Date / Time / DateTime handling
-------------------------------
Time and DateTime are in a pretty poor state in Ruby 1.8. 1.9 already improves drastically
on this by alleviating the year 2038 limitation on 32-bit platforms, but for most people
this still is a problem. I don't know whether 1.9 Time supports non-local timezones, but
this is another issue plaguing DataObjects.

We should investigate whether TimeWithZone from Rails is a good alternative as the default
type returned by DataObjects on 1.8 and possibly 1.9 too if that won't support custom
timezones.

Stored procedure calling
------------------------
Stored procedures are still a pretty common thing in RDBMS land, so we should have an API
that allows for calling these. My knowledge is pretty limited on this, but from what I've
heard it should be possible to unify this.

Future plugins
==============

There are some features that should not be integrated into DO directly, but would be really
nice to have as a plugin so it can be shared between for example different ORM's. This
section contains ideas for these plugins.

Inflection API
--------------
Inflection is something quite a few projects use, ActiveRecord directly for its models,
but also DataMapper uses it for migrations. It would be really nice if DataObjects could
also provide an abstraction for this, so the information is accessible for every RDBMS
in a unified way.
