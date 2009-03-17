package do_hsqldb;

import java.io.UnsupportedEncodingException;
import java.lang.reflect.Field;
import java.net.URI;
import java.net.URISyntaxException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;

import org.jruby.runtime.builtin.IRubyObject;

import data_objects.RubyType;
import data_objects.drivers.AbstractDriverDefinition;

public class HsqldbDriverDefinition extends AbstractDriverDefinition {

    public final static String URI_SCHEME = "hsqldb";
    public final static String RUBY_MODULE_NAME = "Hsqldb";
    public final static String JDBC_DRIVER = "org.hsqldb.jdbcDriver";

    /**
     *
     */
    public HsqldbDriverDefinition() {
        super(URI_SCHEME, RUBY_MODULE_NAME, JDBC_DRIVER);
    }

    /**
     *
     * @param ps
     * @param arg
     * @param idx
     * @throws SQLException
     */
    @Override
    public void setPreparedStatementParam(PreparedStatement ps,
            IRubyObject arg, int idx) throws SQLException {
        switch (RubyType.inferRubyType(arg)) {
        case NIL:
            ps.setNull(idx, Types.NULL);
            break;
        default:
            super.setPreparedStatementParam(ps, arg, idx);
        }
    }

    /**
     *
     * @return
     */
    @Override
    public boolean supportsJdbcGeneratedKeys()
    {
        return false;
    }

    /**
     * Needed if 1.9.x driver is not used (still in beta)
     *
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


    /**
     *
     * @return
     */
    @Override
    public boolean supportsConnectionPrepareStatementMethodWithGKFlag()
    {
        return false;
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

    /**
     *
     * @param sql
     * @param param
     * @return
     */
    private String replace(String sql, Object param)
    {
        return sql.replaceFirst("[?]", param.toString());
    }

    /**
     *
     * @param sql
     * @param param
     * @return
     */
    private String replace(String sql, String param)
    {
        return sql.replaceFirst("[?]", "'" + param.toString() + "'");
    }

    /**
     *
     * @param s
     * @return
     */
    @Override
    public String statementToString(Statement s)
    {
        try {
            Field sqlField = s.getClass().getDeclaredField("sql");
            sqlField.setAccessible(true);
            String sql = sqlField.get(s).toString();
            Field paramsField = s.getClass().getDeclaredField("parameterValues");
            paramsField.setAccessible(true);
            Field paramTypesField = s.getClass().getDeclaredField("parameterTypes");
            paramTypesField.setAccessible(true);
            int[] paramTypes = (int[])paramTypesField.get(s);
            int index = 0;
            for (Object param : (Object[]) paramsField.get(s)) {
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
            return s.toString();
        }
    }

    /**
     *
     * @param connection_uri
     * @return
     * @throws URISyntaxException
     * @throws UnsupportedEncodingException
     */
    @Override
    public URI parseConnectionURI(IRubyObject connection_uri)
        throws URISyntaxException, UnsupportedEncodingException {
        if (!"DataObjects::URI".equals(connection_uri.getType().getName())) {
            if(connection_uri.asJavaString().endsWith(":mem")){
                return new URI(connection_uri.asJavaString() + ":");
            }
        }
        return super.parseConnectionURI(connection_uri);
    }
}
