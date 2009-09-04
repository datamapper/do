#
# Monkey patch DBD::ODBC to pass usernames and passwords along
# to the DB driver correctly
#

# Are you running a new version of DBI?
begin
  require 'dbd/ODBC'
rescue Exception
end

# Or an old version?
begin
  require 'DBD/ODBC/ODBC'
rescue Exception
end

class DBI::DBD::ODBC::Driver < DBI::BaseDriver

    def connect(dbname, user, auth, attr)
        driver_attrs = dbname.split(';')

        if driver_attrs.size > 1
            # DNS-less connection
            drv = ::ODBC::Driver.new
            drv.name = 'Driver1'
            driver_attrs.each do |param|
                pv = param.split('=')
                next if pv.size < 2
                drv.attrs[pv[0]] = pv[1]
            end
            #
            #  These next two lines are new
            #
            drv.attrs['UID'] = user unless user.nil?
            drv.attrs['PWD'] = auth unless auth.nil?

            db = ::ODBC::Database.new
            handle = db.drvconnect(drv)
        else
            # DNS given
            handle = ::ODBC.connect(dbname, user, auth)
        end

        return DBI::DBD::ODBC::Database.new(handle, attr)
    rescue DBI::DBD::ODBC::ODBCErr => err
        raise DBI::DatabaseError.new(err.message)
    end

end
