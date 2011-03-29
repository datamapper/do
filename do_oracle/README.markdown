# do_oracle

* <http://dataobjects.info>

## Description

An Oracle driver for DataObjects.

## Features/Problems

This driver implements the DataObjects API for the Oracle relational database.

## Synopsis

An example of usage:

    @connection = DataObjects::Connection.new("oracle://employees")
    @reader = @connection.create_command('SELECT * FROM users').execute_reader
    @reader.next!

In the future, the `Connection` constructor will be able to be passed either a
DataObjects-style URL or JDBC style URL, when using do\_oracle on JRuby. However,
this feature is not currently working reliably and is a known issue.

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

    gem install do_oracle

To compile and install from source:

* For MRI/Rubinius extensions:
  * Install the `gcc` compiler. On OS X, you should install XCode tools. On
    Ubuntu, run `apt-get install build-essential`.
  * THESE INSTRUCTIONS ARE CURRENTLY INCOMPLETE!

 * For JRuby extensions:
   * Install the Java Development Kit (provided if you are
     on a recent version of Mac OS X) from <http://java.sun.com>.
   * Install a recent version of JRuby. Ensure `jruby` is in your `PATH` and/or
     you have configured the `JRUBY_HOME` environment variable to point to your
     JRuby installation.
   * Install `data_objects` and `do_jdbc` with `jruby -S rake install`.

 * Then, install this driver with `(jruby -S) rake install`.

For more information, see the Oracle driver wiki page:
<http://wiki.github.com/datamapper/do/oracle>.

## Developers

Follow the above installation instructions. Additionally, you'll need:
  * `rspec` gem for running specs.
  * `YARD` gem for generating documentation.

See the DataObjects wiki for more comprehensive information on installing and
contributing to the JRuby-variant of this driver:
<http://wiki.github.com/datamapper/do/jruby>.

### install oracle jdbc driver in maven

$ mvn install
will produce an error and give you message like (maybe with a different version). please follow these instructions to install the

  Try downloading the file manually from:
      http://www.oracle.com/technology/software/tech/java/sqlj_jdbc/index.html

  Then, install it using the command:
      mvn install:install-file -DgroupId=com.oracle -DartifactId=ojdbc14 -Dversion=10.2.0.3.0 -Dpackaging=jar -Dfile=/path/to/file

  Alternatively, if you host your own repository you can deploy the file there:
      mvn deploy:deploy-file -DgroupId=com.oracle -DartifactId=ojdbc14 -Dversion=10.2.0.3.0 -Dpackaging=jar -Dfile=/path/to/file -Durl=[url] -DrepositoryId=[id]

### Specs

To run specs:

    rake spec

To run specs without compiling extensions first:

    rake spec_no_compile

To run individual specs:

    rake spec TEST=spec/connection_spec.rb

(Note that the `rake` task uses a `TEST` parameter, not `SPEC`. This is because
the `Rake::TestTask` is used for executing the Bacon specs).

## License

This code is licensed under an **MIT (X11) License**. Please see the
accompanying `LICENSE` file.
