package do_postgres;

import data_objects.drivers.AbstractDriverDefinition;
import java.util.Properties;

public class PostgresDriverDefinition extends AbstractDriverDefinition {

    @Override
    public boolean supportsJdbcGeneratedKeys()
    {
        return false;
    }

    @Override
    public boolean supportsJdbcScrollableResultSets() {
        return true;
    }

    @Override
    public boolean supportsConnectionEncodings()
    {
        return true;
    }

    @Override
    public void setEncodingProperty(Properties props, String encodingName) {
        // this is redundant as of Postgres 8.0, according to the JDBC documentation:
        // http://jdbc.postgresql.org/documentation/80/connect.html
        props.put("charSet", encodingName);
    }

}
