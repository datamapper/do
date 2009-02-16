package data_objects.drivers;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 *
 * @author alexbcoles
 */
public abstract class AbstractDriverDefinition implements DriverDefinition {

    public abstract boolean supportsJdbcGeneratedKeys();

    public abstract boolean supportsJdbcScrollableResultSets();

    public boolean supportsConnectionPrepareStatementMethodWithGKFlag() {
        return true;
    }

    public ResultSet getGeneratedKeys(Connection connection) {
        return null;
    }

    public String quoteString(String str) {
        StringBuffer quotedValue = new StringBuffer(str.length() + 2);
        quotedValue.append("\'");
        quotedValue.append(str);
        quotedValue.append("\'");
        return quotedValue.toString();
    }

    public String toString(PreparedStatement ps) {
        return ps.toString();
    }

}
