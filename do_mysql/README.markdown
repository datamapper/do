# do_mysql

* <http://dataobjects.info>

## Description

A MySQL driver for DataObjects.

## Features/Problems

This driver implements the DataObjects API for the MySQL relational database.

## Synopsis

An example of usage:

```ruby
# default user (root, no password); default port (3306)
DataObjects::Connection.new("mysql://host/database")
# specified user, specified port
DataObjects::Connection.new("mysql://user:pass@host:8888/database")

@connection = DataObjects::Connection.new("mysql://localhost/employees")
@reader = @connection.create_command('SELECT * FROM users').execute_reader
@reader.next!
```

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

    gem install do_mysql

If installing the MRI/1.9/Rubinius extension on OS X and you install a version
of MySQL that was built for only a single architecture, you will need to set
`ARCHFLAGS` appropriately:

    sudo env ARCHFLAGS="-arch i386" gem install do_mysql

To compile and install from source:

* Install rake-compiler: `gem install rake-compiler`.

* For MRI/Rubinius extensions:
  * Install the `gcc` compiler. On OS X, you should install XCode tools. On
    Ubuntu, run `apt-get install build-essential`.
  * Install Ruby and MySQL.
  * Install the Ruby and MySQL development headers.
    * On Debian-Linux distributions, you can install the following packages
      with `apt`: `ruby-dev` `libmysqlclient15-dev`.
  * If you want to cross-compile for Windows:
    * Install MinGW:
      * On Debian-Linux distributions, you can install the following package
        with `apt`: `mingw32`.
      * On OS X, this can install the following package with MacPorts: `i386-mingw32-gcc`.
    * Run `rake-compiler cross-ruby`.
    * Run `rake-compiler update-config`.

 * Then, install this driver with `(jruby -S) rake install`.

For more information, see the MySQL driver wiki page:
<http://wiki.github.com/datamapper/do/mysql>.

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
