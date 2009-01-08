package do_sqlite3;

import data_objects.drivers.AbstractDriverDefinition;

public class Sqlite3DriverDefinition extends AbstractDriverDefinition {

    public boolean supportsJdbcGeneratedKeys()
    {
        return true;
    }

    public boolean supportsConnectionPrepareStatementMethodWithGKFlag()
    {
        return false;
    }

    //@Override
    public String quoteString(String str) {
        StringBuffer quotedValue = new StringBuffer(str.length() + 2);
        quotedValue.append("\'");
        quotedValue.append(str.replaceAll("'", "''"));
        quotedValue.append("\'");
        return quotedValue.toString();
    }

}