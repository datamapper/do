# do_sqlserver

* <http://dataobjects.info>

## Description

A Microsoft SQL Server adapter for DataObjects,

## Features/Problems

This driver implements the DataObjects API for the Microsoft SQL Server
relational database.

Problems with MRI implementation (unreleased):

* Relies on DBI's support for either ADO or ODBC with FreeTDS
* Has no tests and no data type conversion yet

## Synopsis

Examples of usage:

    # default port (using SQL Server Express Edition)
    DataObjects::Connection.new('sqlserver://user:pass@host/database;instance=SQLEXPRESS')
    # port specified (using SQL Server Express Edition)
    DataObjects::Connection.new('sqlserver://user:pass@host:1433/database;instance=SQLEXPRESS')

    @connection = DataObjects::Connection.new("sqlserver://john:p3$$@localhost:1433/userinfo")
    @reader = @connection.create_command('SELECT * FROM users').execute_reader
    @reader.next!

* See also the accompanying `CONNECTING.markdown`.

## Requirements

This driver is provided for the following platforms:
 * JRuby 1.3.1 + (1.4+ recommended).

Code for the following platform is in the repository, but is still under EARLY
DEVELOPMENT and is neither RELEASED or SUPPORTED:
 * Ruby MRI (1.8.6/7), 1.9: tested on Linux, Mac OS X and Windows platforms.

Additionally you should have the following prerequisites:
 * `data_objects` gem
 * `do_jdbc` gem (shared library), if running on JRuby.
 * `dbi` gem, if running on MRI.
 * On non-Windows platforms, unixODBC and FreeTDS libraries.

## Install

To install the gem:

    gem install do_sqlserver

To compile and install from source:

 * For MRI:
  * Installation of do_sqlserver is significantly more involved than for other
    drivers. Please see the accompanying `INSTALL.markdown`.

 * For JRuby extensions:
   * Install the Java Development Kit (provided if you are
     on a recent version of Mac OS X) from <http://java.sun.com>.
   * Install a recent version of JRuby. Ensure `jruby` is in your `PATH` and/or
     you have configured the `JRUBY_HOME` environment variable to point to your
     JRuby installation.
   * Install `data_objects` and `do_jdbc` with `jruby -S rake install`.

 * Then, install this driver with `(jruby -S) rake install`.

Then:

    sudo gem install do_sqlserver

For more information, see the SQL Server driver wiki page:
<http://wiki.github.com/datamapper/do/sql-server>.

## Developers

Follow the above installation instructions. Additionally, you'll need:
  * `rspec` gem for running specs.
  * `YARD` gem for generating documentation.

See the DataObjects wiki for more comprehensive information on installing and
contributing to the JRuby-variant of this driver:
<http://wiki.github.com/datamapper/do/jruby>.

To run specs:

    rake spec

To run specs without compiling extensions first:

    rake spec_no_compile

To run individual specs:

    rake spec SPEC=spec/connection_spec.rb

## License

This code is licensed under an **MIT (X11) License**. Please see the
accompanying `LICENSE` file.
