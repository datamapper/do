package do_derby;

import data_objects.drivers.AbstractDriverDefinition;

public class DerbyDriverDefinition extends AbstractDriverDefinition {

    @Override
    public boolean supportsJdbcGeneratedKeys()
    {
        return true;
    }

    @Override
    public boolean supportsJdbcScrollableResultSets() {
        return true;
    }
}
