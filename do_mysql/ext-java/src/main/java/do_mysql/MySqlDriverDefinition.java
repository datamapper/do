package do_mysql;

import java.sql.PreparedStatement;

import data_objects.drivers.AbstractDriverDefinition;

public class MySqlDriverDefinition extends AbstractDriverDefinition {

    public boolean supportsJdbcGeneratedKeys()
    {
        return true;
    }

    public boolean supportsJdbcScrollableResultSets()
    {
        return true;
    }

    //@Override
    public String quoteString(String str) {
        StringBuffer quotedValue = new StringBuffer(str.length() + 2);
        quotedValue.append("\'");
        quotedValue.append(str.replaceAll("'", "\\\\'"));
        // TODO: handle backslashes
        quotedValue.append("\'");
        return quotedValue.toString();
    }

    public String toString(PreparedStatement ps) {
	return ps.toString().replaceFirst(".*].-\\s*", "");
    }

}