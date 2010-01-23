# do_jdbc 'Doppio'

* <http://dataobjects.info>

## Description

Native JDBC Support for DataObjects.

## Features/Problems

do_jdbc is a gem wrapper for the common library that uses JDBC to support DO
drivers running on the JRuby implementation.

## Synopsis

This is a support library and should not be used directly.

## Requirements

 * JRuby 1.3.1 + (1.4+ recommended)
 * `data_objects` gem

## Install

To install the gem:

    jruby -S gem install do_jdbc

Normally, you would not install do_jdbc directly. Instead it should be installed
when installing DO drivers on JRuby, thanks to RubyGems dependency resolution.

To compile and install from source:

 * Install the Java Development Kit (provided if you are on a recent version of
   Mac OS X) from <http://java.sun.com>
 * Install a recent version of JRuby. Ensure `jruby` is in your `PATH` and/or
   you have configured the `JRUBY_HOME` environment variable to point to your
   JRuby installation.
 * Install `data_objects` with `jruby -S rake install`.
 * Install this driver with `jruby -S rake install`.

## Developers

See the DataObjects wiki for more comprehensive information:
<http://wiki.github.com/datamapper/do/jruby>.

## License

This code is licensed under an **MIT (X11) License**. Please see the
accompanying `LICENSE` file.
