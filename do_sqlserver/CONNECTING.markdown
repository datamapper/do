CONNECTING
==========

Various notes (needs to be cleaned-up).

See:
 * <http://blogs.msdn.com/sqlexpress/archive/2004/07/23/192044.aspx>
 * <http://blogs.msdn.com/b/bethmassi/archive/2008/09/17/enabling-remote-sql-express-2008-network-connections-on-vista.aspx>


Example Setup
-------------

* In Visual Studio, click Server Explorer
* Right click Data Connections
* Create New SQL Server Database
* Server Name: YOURPCNAME\SQLEXPRESS
* Use Windows Authentication
* #Use SQL Server Authentication
* #User name: do_test
* #Password:  do_test
* New database name: do_test

See:
<http://social.msdn.microsoft.com/Forums/en-US/Vsexpressinstall/thread/aaf2f68c-4a40-44c8-b7ee-b2f5d94e23c3>

---


Tips
----

* Check the password is not required to be set on first connect.
* Test you can connect locally. Either through Visual Studio SQL Server tools,
  SQL Server Management Studio, or simply using telnet: `telnet localhost 4322`.
* Configure Firewall correctly: http://support.microsoft.com/kb/287932
* Specify an instance: in the DO URL append `INSTANCE=SQLEXPRESS`.
* You can not add the instance to the hostname, i.e. `192.168.2.110\SQLEXPRESS`
  as the underlying jTDS driver needs a URL that looks like this:
  `jdbc:jtds:sqlserver://192.168.2.110:1433/do_test;instance=SQLEXPRESS`.
