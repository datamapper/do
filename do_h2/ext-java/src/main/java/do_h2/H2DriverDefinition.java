package do_h2;

import data_objects.drivers.AbstractDriverDefinition;

public class H2DriverDefinition extends AbstractDriverDefinition {

    @Override
    public boolean supportsJdbcGeneratedKeys()
    {
        return true;
    }

    @Override
    public boolean supportsJdbcScrollableResultSets()
    {
        return true;
    }

}
