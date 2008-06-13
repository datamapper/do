package do_mysql;

import data_objects.drivers.AbstractDriverDefinition;

public class MySqlDriverDefinition extends AbstractDriverDefinition {

    public boolean supportsJdbcGeneratedKeys()
    {
        return true;
    }

}