package do_postgres;

import data_objects.drivers.AbstractDriverDefinition;

public class PostgresDriverDefinition extends AbstractDriverDefinition {

    public boolean supportsJdbcGeneratedKeys()
    {
        return false;
    }

}