DataObjects README
==================

DataObjects.rb is an attempt to rewrite existing Ruby database drivers to
conform to one, standard interface.

At present, PostgreSQL, MySQL and SQLite drivers are available. More drivers are
currently under development. If you feel like living on the edge, install and
test drivers directly from this repository.

Introduction
------------

To connect and send queries to databases, DataObjects relies on native
extensions. Native extensions have been written in both C (for the Ruby MRI
platform) and Java (for the JRuby platform). Individual drivers may include
extensions for both Ruby MRI and JRuby, or one or the other.

C extensions have been written using according to each vendor API. Java drivers
use the standard JDBC API. Although there are dialectical differences between
the Java drivers, the JDBC API ensures a reasonable amount of commonality. As
such, the Java extensions rely on a common do\_jdbc\_support gem, which wraps
code that is common to all of the Java extensions.

Installation
------------

To install a driver from the repository `cd` into the driver directory and use
the provided `rake install` task to install for the default platform.

If a driver includes extensions for both MRI or JRuby platforms, you can be
explicit about which platform you wish to install the extension for as follows:

    rake install:mri
    jruby -S rake install:jruby

Copyright and Licensing
-----------------------

Please see the copyright notices in each individual driver README or LICENSE
file. Java-based drivers bundle JDBC driver JAR files, which may be provided
under a license that is more restrictive than the MIT License used by the
data\_objects gem itself.
