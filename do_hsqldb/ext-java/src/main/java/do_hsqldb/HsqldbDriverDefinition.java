package do_hsqldb;

import java.lang.reflect.Field;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import org.jruby.runtime.builtin.IRubyObject;

import data_objects.RubyType;
import data_objects.drivers.AbstractDriverDefinition;


public class HsqldbDriverDefinition extends AbstractDriverDefinition {

    public final static String URI_SCHEME = "hsqldb";
    public final static String RUBY_MODULE_NAME = "Hsqldb";

    public HsqldbDriverDefinition() {
        super(URI_SCHEME, RUBY_MODULE_NAME);
    }

    @Override
    public void setPreparedStatementParam(PreparedStatement ps,
            IRubyObject arg, int idx) throws SQLException {
        switch (RubyType.getRubyType(arg.getType().getName())) {
        case NIL:
            // XXX ps.getParameterMetaData().getParameterType(idx) produces
            // com.mysql.jdbc.ResultSetMetaData:397:in `getField': java.lang.NullPointerException
            // from com.mysql.jdbc.ResultSetMetaData:275:in `getColumnType'
            ps.setNull(idx, Types.NULL);
            break;
        default:
            super.setPreparedStatementParam(ps, arg, idx);
        }
    }

    @Override
    public boolean supportsJdbcGeneratedKeys()
    {
        return false;
    }

    /**
     * Needed if 1.9.x driver is not used (still in beta)
     * @param connection
     * @return
     */
    @Override
    public ResultSet getGeneratedKeys(Connection connection) {
        try {
            return connection.prepareStatement("CALL IDENTITY()").executeQuery();
        } catch (SQLException ex) {
            return null;
        }
    }


    @Override
    public boolean supportsConnectionPrepareStatementMethodWithGKFlag()
    {
        return false;
    }

    @Override
    public boolean supportsCalendarsInJDBCPreparedStatement() {
        return false;
    }

    @Override
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

    @Override
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
            for (Object param : (Object[]) paramsField.get(ps)) {
                switch (paramTypes[index++]) {
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
