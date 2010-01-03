# Sql Server JDBC Driver

This is a Sql Server JDBC driver packaged as gem for convenient installation in JRuby.

The do_sqlserver driver extension should automatically download and install this
gem for you, by virtue of the RubyGems requirement system.

If you want to load this driver directly:

   require 'do_jdbc/sqlserver'

to make the driver accessible to JDBC and DataObjects code running in JRuby.

## Copyright and Licensing

This gem bundles the jtds JDBC Driver, http://jtds.sourceforge.net/

The jtds JDBC Driver is available under the terms of the LGPL License. See
http://www.gnu.org/copyleft/lesser.html for more details.
