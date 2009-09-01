do_sqlserver
============

Description:
------------

An SQL Server adapter for DataObjects

Features/Problems:
------------------

* Relies on DBI's support for either ADO or ODBC with FreeTDS
* Has no tests and no data type conversion yet

Synopsis:
---------

DataObjects::Connection.new('sqlserver:///mydatabase')

* See the accompanying `CONNECTING.markdown`.

Requirements:
------------

* DBI gem
* On non-Windows platforms, unixODBC and FreeTDS libraries

Install:
--------

* Installation of do_sqlserver is signficantly more involved than for other
  drivers. Please see the accompanying `INSTALL.markdown`.

Then:

    sudo gem install do_sqlserver

License:
--------

(The MIT License)

Copyright (c) 2009 Clifford Heath

See accompanying LICENSE.
