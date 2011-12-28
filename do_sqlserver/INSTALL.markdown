INSTALLING
==========

JRuby variant driver
--------------------

  * Install the jTDS JDBC Driver. For your convenience, DO packages it as a Ruby
    Gem. If installing from source, `cd` to `../jdbc_drivers/sqlserver/` and run
    `rake install`.
  * There are currently no other prerequisites for installation.

1.8.6/7 (MRI) and 1.9.x (YARV) variant
--------------------------------------

  1. Install the DBI, DBD::ODBC dependencies and ODBC Binding for Ruby:

        sudo gem install dbi dbd-odbc ruby-odbc

  2. You must also have FreeTDS or [unixODBC][unixodbc] (SQL Server license for
     unixODBC is commercially licensed though) installed.

  3. To install FreeTDS on OS X, you can use MacPorts:

        sudo port install freetds

        ****************************************************************
        Configuration file freetds.conf does not exist and has been created using
            /opt/local/etc/freetds/freetds.conf.sample
        Configuration file locales.conf does not exist and has been created using
            /opt/local/etc/freetds/locales.conf.sample
        Configuration file pool.conf does not exist and has been created using
            /opt/local/etc/freetds/pool.conf.sample
        ****************************************************************

     or Brew:

        sudo brew install freetds

  * Then edit your ODBC configuration and add the FreeTDS driver.

    * Using a text editor: On OS X, open `/Library/ODBC/odbcinst.ini` and add
      the following entries:

            [FreeTDS]
            Driver = /opt/local/lib/libtdsodbc.so
            Setup  = /opt/local/lib/libtdsodbc.so

    * You can also use a GUI for this (provided in Mac OS X 10.3 - 10.5;
      [ODBCManager][odbcmanager] available for OS X 10.6)..
      * Start ODBC Manager
      * Go to *Drivers*, *Add...*
      * Enter _FreeTDS_ as Driver Name.
      * Enter `/usr/local/freetds/lib/libtdsodbc.so` as Driver File
      * Enter `/usr/local/freetds/lib/libtdsodbc.so` as Setup File
      * Select *System*
      * Click *OK*.


[rubyodbc]:http://www.ch-werner.de/rubyodbc/README
[unixodbc]:http://www.unixodbc.org/
[odbcmanager]:http://www.odbcmanager.net/index.php
