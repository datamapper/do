package do_h2;

import data_objects.drivers.AbstractDriverDefinition;

public class H2DriverDefinition extends AbstractDriverDefinition {
    public final static String URI_SCHEME = "h2";
    public final static String RUBY_MODULE_NAME = "H2";
    public final static String JDBC_DRIVER = "org.h2.Driver";

    /**
     *
     */
    public H2DriverDefinition(){
        super(URI_SCHEME, RUBY_MODULE_NAME, JDBC_DRIVER);
    }

    /**
     *
     * @return
     */
    @Override
    public boolean supportsJdbcGeneratedKeys()
    {
        return true;
    }

    /**
     *
     * @return
     */
    @Override
    public boolean supportsJdbcScrollableResultSets()
    {
        return true;
    }

}
