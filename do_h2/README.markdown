# do_h2

* <http://dataobjects.info>

## Description

An H2 driver for DataObjects.

## Features/Problems

This driver implements the DataObjects API for the H2 relational database.
This driver is currently provided only for JRuby.

## Synopsis

An example of usage:

    @connection = DataObjects::Connection.new("h2://employees")
    @reader = @connection.create_command('SELECT * FROM users').execute_reader
    @reader.next!

The `Connection` constructor should be passed either a DataObjects-style URL or
JDBC-style URL:

    h2://employees
    jdbc:h2:mem

## Requirements

 * JRuby 1.3.1 + (1.4+ recommended)
 * `data_objects` gem
 * `do_jdbc` gem (shared library)

## Install

To install the gem:

    jruby -S gem install do_h2

To compile and install from source:

 * Install the Java Development Kit (provided if you are on a recent version of
   Mac OS X) from <http://java.sun.com>
 * Install a recent version of JRuby. Ensure `jruby` is in your `PATH` and/or
   you have configured the `JRUBY_HOME` environment variable to point to your
   JRuby installation.
 * Install `data_objects` and `do_jdbc` with `jruby -S rake install`.
 * Install this driver with `jruby -S rake install`.

For more information, see the H2 driver wiki page:
<http://wiki.github.com/datamapper/do/h2>.

## Developers

Follow the above installation instructions. Additionally, you'll need:
  * `rspec` gem for running specs.
  * `YARD` gem for generating documentation.

See the DataObjects wiki for more comprehensive information:
<http://wiki.github.com/datamapper/do/jruby>.

To run specs:

    jruby -S rake spec

To run specs without compiling extensions first:

    jruby -S rake spec_no_compile

To run individual specs:

    jruby -S rake spec SPEC=spec/connection_spec.rb

## License

This code is licensed under an **MIT (X11) License**. Please see the
accompanying `LICENSE` file.
