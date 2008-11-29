DataObjects README
==================

DataObjects.rb is an attempt to rewrite existing Ruby database drivers to
conform to one, standard interface.

At present, PostgreSQL, MySQL and SQLite drivers are available. More drivers are
currently under development. If you feel like living on the edge, install and
test drivers directly from this repository.

Introduction
------------

To connect to and query the database, DataObjects relies on native extensions.
Native extensions have been written in both C (for the MRI/Ruby 1.8.6 platform)
and Java (for the JRuby platform). Individual drivers may include extensions for
both Ruby MRI and JRuby, or one or the other.

C extensions have been written using according to each vendor API. Java drivers
use the standard JDBC API. Although there are dialectical differences between
the Java drivers, the JDBC API ensures a reasonable amount of commonality. As
such, the Java extensions rely on a common do\_jdbc gem, which wraps code that
is common to all of the Java extensions.

Installation
------------

To install a driver from the repository `cd` into the driver directory and use
the provided `rake install` task to install for the default platform.

Copyright and Licensing
-----------------------

Please see the copyright notices in each individual driver README or LICENSE
file. Java-based drivers bundle JDBC driver JAR files, which may be provided
under a license that is more restrictive than the MIT License used by the
data\_objects gem itself.
