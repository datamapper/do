package data_objects.drivers;

import java.sql.Connection;
import java.sql.ResultSet;

/**
 *
 * @author alexbcoles
 */
public abstract class AbstractDriverDefinition implements DriverDefinition {

    public abstract boolean supportsJdbcGeneratedKeys();

    public ResultSet getGeneratedKeys(Connection connection) {
        return null;
    }
    
    public String quoteString(String str) {
        return null;
    }

}
