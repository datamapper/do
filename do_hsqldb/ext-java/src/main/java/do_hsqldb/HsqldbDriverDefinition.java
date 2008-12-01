package do_hsqldb;

import data_objects.drivers.AbstractDriverDefinition;

public class HsqldbDriverDefinition extends AbstractDriverDefinition {

    public boolean supportsJdbcGeneratedKeys()
    {
        return false;
    }

}