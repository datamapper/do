package do_sqlite3;

import data_objects.drivers.AbstractDriverDefinition;

public class Sqlite3DriverDefinition extends AbstractDriverDefinition {

    public boolean supportsJdbcGeneratedKeys()
    {
        return true;
    }

}