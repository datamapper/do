DataObjects README
==================

DataObjects.rb is an attempt to rewrite existing Ruby database drivers to
conform to one, standard interface.

At present the following drivers are available:

<table>
  <tr>
    <th>Database Vendor</th>
    <th>MRI (1.8.6/7) / 1.9</th>
    <th>JRuby</th>
  </tr>
  <tr>
    <td>MySQL</td>
    <td>x</td>
    <td>x</td></tr>
  <tr>
    <td>Oracle</td>
    <td>x</td>
    <td>x</td></tr>
  <tr>
    <td>PostgreSQL</td>
    <td>x</td>
    <td>x</td></tr>
  <tr>
    <td>SQLite3</td>
    <td>x</td>
    <td>x</td></tr>
  <tr>
    <td>Derby</td>
    <td>-</td>
    <td>x</td></tr>
  <tr>
    <td>H2</td>
    <td>-</td>
    <td>x</td></tr>
  <tr>
    <td>HSQLDB</td>
    <td>-</td>
    <td>x</td></tr>
  <tr>
    <td>SQL Server</td>
    <td><em>pending</em></td>
    <td>x</td></tr>
  <tr>
    <td>OpenEdge</td>
    <td>-</td>
    <td>x</td></tr>
</table>

There is experimental support for [Rubinius][rubinius].

More drivers are
currently under development. If you feel like living on the edge, install and
test drivers directly from this repository.

Introduction
------------

To connect to and query the database, DataObjects relies on native extensions.
Native extensions have been written in both C (for Ruby 1.8.6/7 (MRI), Ruby
1.9.x (YARV) and Rubinius platform) and Java (for the JRuby platform).
Individual drivers may include extensions for both Ruby MRI and JRuby, or one
or the other.

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

Please see the copyright notices in each individual driver README.markdown or
LICENSE file. Java-based drivers bundle JDBC driver JAR files, which may be
provided under a license that is more restrictive than the MIT License used by the
data\_objects gem itself.

[rubinius]:http://rubini.us/
