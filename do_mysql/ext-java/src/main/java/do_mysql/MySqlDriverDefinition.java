package do_mysql;

import java.io.IOException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.Properties;

import org.jruby.Ruby;
import org.jruby.runtime.builtin.IRubyObject;

import data_objects.RubyType;
import data_objects.drivers.AbstractDriverDefinition;

import java.sql.DriverManager;
import java.util.regex.Matcher;
import java.util.regex.Pattern;


public class MySqlDriverDefinition extends AbstractDriverDefinition {

    public final static String URI_SCHEME = "mysql";
    public final static String RUBY_MODULE_NAME = "Mysql";
    private final static String UTF8_ENCODING = "UTF-8";
    public final static String JDBC_DRIVER = "com.mysql.jdbc.Driver";

    /**
     *
     */
    public MySqlDriverDefinition() {
        super(URI_SCHEME, RUBY_MODULE_NAME, JDBC_DRIVER);
    }

    /**
     *
     * @param runtime
     * @param rs
     * @param col
     * @param type
     * @return
     * @throws SQLException
     * @throws IOException
     */
    @Override
    public IRubyObject getTypecastResultSetValue(Ruby runtime,
            ResultSet rs, int col, RubyType type) throws SQLException,
            IOException {
        switch (type) {
        case FIXNUM:
            switch (rs.getMetaData().getColumnType(col)) {
            case Types.TINYINT:
                boolean bool = rs.getBoolean(col);
                return runtime.newBoolean(bool);
            }
        default:
            return super.getTypecastResultSetValue(runtime, rs, col, type);
        }
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
            // XXX ps.getParameterMetaData().getParameterType(idx) produces
            // com.mysql.jdbc.ResultSetMetaData:397:in `getField': java.lang.NullPointerException
            // from com.mysql.jdbc.ResultSetMetaData:275:in `getColumnType'
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

    /**
     *
     * @return
     */
    @Override
    public boolean supportsConnectionEncodings()
    {
        return true;
    }

    /**
     *
     * @return
     */
    @Override
    public Properties getDefaultConnectionProperties() {
        Properties props = new Properties();

        // by default we connect with root and a empty password
        props.put("user", "root");
        props.put("password", "");

        props.put("useUnicode", "yes");
        // removed NO_AUTO_VALUE_ON_ZERO because of MySQL bug http://bugs.mysql.com/bug.php?id=42270
        // added NO_BACKSLASH_ESCAPES so that backslashes should not be escaped as in other databases
        props.put("sessionVariables", "sql_auto_is_null=0,sql_mode='ANSI,NO_BACKSLASH_ESCAPES,NO_DIR_IN_CREATE,NO_ENGINE_SUBSTITUTION,NO_UNSIGNED_SUBTRACTION,TRADITIONAL'");
        // by default enable auto reconnection
        props.put("autoReconnect","true");
        return props;
    }

    /**
     *
     * @param props
     * @param encodingName
     */
    @Override
    public void setEncodingProperty(Properties props, String encodingName) {
        props.put("characterEncoding", encodingName);
    }

    /**
     *
     * @param runtime
     * @param connection
     * @param url
     * @param props
     * @return
     * @throws SQLException
     */
    @Override
    public java.sql.Connection getConnectionWithEncoding(Ruby runtime,
            IRubyObject connection, String url, Properties props) throws SQLException {
        java.sql.Connection conn;
        try {
            conn = DriverManager.getConnection(url, props);
        } catch (SQLException eex) {
            /*
             * Used to get an exception that indicated a bad character encoding,
             * but that doesn't seem to be the case anywhere.  So instead we'll
             * just try blindly to reconnect once with UTF8_ENCODING.

            Pattern p = Pattern.compile("Unsupported character encoding '(.+)'\\.");
            Matcher m = p.matcher(eex.getMessage());

            if (m.find()) {
                // re-attempt connection, but this time with UTF-8
                // set as the encoding
                runtime.getWarnings().warn(String.format(
                        "Encoding %s is not a known Ruby encoding for %s\n",
                        m.group(1), RUBY_MODULE_NAME));

            */

            setEncodingProperty(props, UTF8_ENCODING);
            API.setInstanceVariable(connection, "@encoding", runtime.newString(UTF8_ENCODING));
            conn = DriverManager.getConnection(url, props);
        }
        return conn;
    }

    /**
     *
     * @param s
     * @return
     */
    @Override
    public String statementToString(Statement s) {
        return s.toString().replaceFirst(".*].-\\s*", "");
    }

}
