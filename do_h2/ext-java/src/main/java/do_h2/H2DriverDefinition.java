package do_h2;

import data_objects.drivers.AbstractDriverDefinition;

public class H2DriverDefinition extends AbstractDriverDefinition {
    public final static String URI_SCHEME = "h2";
    public final static String RUBY_MODULE_NAME = "H2";

    public H2DriverDefinition(){
        super(URI_SCHEME, RUBY_MODULE_NAME);
    }

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
