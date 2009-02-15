package do_hsqldb;

import java.lang.reflect.Field;
import java.sql.PreparedStatement;
import java.sql.Types;

import data_objects.drivers.AbstractDriverDefinition;

public class HsqldbDriverDefinition extends AbstractDriverDefinition {

    public boolean supportsJdbcGeneratedKeys()
    {
        return false;
    }

    public boolean supportsConnectionPrepareStatementMethodWithGKFlag()
    {
        return false;
    }

    public boolean supportsJdbcScrollableResultSets()
    {
        return true;
    }

    private String replace(String sql, Object param)
    {
	return sql.replaceFirst("[?]", param.toString());
    }

    private String replace(String sql, String param)
    {
	return sql.replaceFirst("[?]", "'" + param.toString() + "'");
    }

    public String toString(PreparedStatement ps)
    {
	try {
	    Field sqlField = ps.getClass().getDeclaredField("sql");
	    sqlField.setAccessible(true);
	    String sql = sqlField.get(ps).toString();
	    Field paramsField = ps.getClass().getDeclaredField("parameterValues");
	    paramsField.setAccessible(true);
	    Field paramTypesField = ps.getClass().getDeclaredField("parameterTypes");
	    paramTypesField.setAccessible(true);
	    int[] paramTypes = (int[])paramTypesField.get(ps);
	    int index = 0;
	    for(Object param: (Object[])paramsField.get(ps)) {
		switch(paramTypes[index++]) {
		case Types.CHAR:
		case Types.LONGVARCHAR:
		case Types.VARCHAR:
		    sql = replace(sql, param.toString());
		default:
		    sql = replace(sql, param);
		}
	    }
	    return sql;
	}
	catch(Exception e) {
	    // just fall to the toString of the PreparedStatement
	    return ps.toString();
	}
    }
}