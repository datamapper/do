# do_sqlite3

* <http://dataobjects.info>

## Description

A SQLite3 driver for DataObjects.

## Features/Problems

This driver implements the DataObjects API for the SQLite3 relational database.

## Synopsis

An example of usage:

    @connection = DataObjects::Connection.new("sqlite3://employees")
    @reader = @connection.create_command('SELECT * FROM users').execute_reader
    @reader.next!

## Requirements

This driver is provided for the following platforms:
 * Ruby MRI (1.8.6/7), 1.9: tested on Linux, Mac OS X and Windows platforms.
 * JRuby 1.3.1 + (1.4+ recommended).
 * Rubinius (experimental).

Additionally you should have the following prerequisites:
 * `data_objects` gem
 * `do_jdbc` gem (shared library), if running on JRuby.

## Install

To install the gem:

    gem install do_sqlite3

To compile and install from source:

 * Install rake-compiler: `gem install rake-compiler`.

 * For MRI/Rubinius extensions:
   * Install the `gcc` compiler. On OS X, you should install XCode tools. On
     Ubuntu, run `apt-get install build-essential`.
   * Install Ruby and SQLite3.
   * Install the Ruby and SQLite3 development headers.
     * On Debian-Linux distributions, you can install the following packages
       with `apt`: `ruby-dev` `libsqlite3-dev`.
   * If you want to cross-compile for Windows:
     * Install MinGW:
       * On Debian-Linux distributions, you can install the following package
         with `apt`: `mingw32`.
       * On OS X, this can install the following package with MacPorts: `i386-mingw32-gcc`.
     * Run `rake-compiler cross-ruby`.
     * Run `rake-compiler update-config`.

 * For JRuby extensions:
   * Install the Java Development Kit (provided if you are
     on a recent version of Mac OS X) from <http://java.sun.com>.
   * Install a recent version of JRuby. Ensure `jruby` is in your `PATH` and/or
     you have configured the `JRUBY_HOME` environment variable to point to your
     JRuby installation.
   * Install `data_objects` and `do_jdbc` with `jruby -S rake install`.

 * Then, install this driver with `(jruby -S) rake install`.

For more information, see the SQLite3 driver wiki page:
<http://wiki.github.com/datamapper/do/sqlite3>.

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
