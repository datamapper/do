package do_mysql;

import data_objects.drivers.AbstractDriverDefinition;

public class MySqlDriverDefinition extends AbstractDriverDefinition {

    public boolean supportsJdbcGeneratedKeys()
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

}