package do_sqlserver;

import java.lang.reflect.Field;
import java.net.URI;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.jruby.Ruby;
import org.jruby.runtime.builtin.IRubyObject;

import data_objects.drivers.AbstractDriverDefinition;
import data_objects.util.JDBCUtil;

public class SqlServerDriverDefinition extends AbstractDriverDefinition {

    public final static String URI_SCHEME = "sqlserver";
    // . will be replaced with : in Connection.java before connection
    public final static String JDBC_URI_SCHEME = "jtds.sqlserver";
    public final static String RUBY_MODULE_NAME = "SqlServer";
    private final static String UTF8_ENCODING = "UTF-8";
    public final static String JDBC_DRIVER = "net.sourceforge.jtds.jdbc.Driver";

    /**
     *
     */
    public SqlServerDriverDefinition() {
        super(URI_SCHEME, JDBC_URI_SCHEME, RUBY_MODULE_NAME, JDBC_DRIVER);
    }

    /**
     *
     * @return
     */
    @Override
    public boolean supportsJdbcGeneratedKeys() {
        return true;
    }

    /**
     *
     * @return
     */
    @Override
    public boolean supportsJdbcScrollableResultSets() {
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
     * @param props
     * @param encodingName
     */
    @Override
    public void setEncodingProperty(Properties props, String encodingName) {
        props.put("charset", encodingName);
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
        try  {
            conn = DriverManager.getConnection(url, props);
        } catch (SQLException eex) {
            Pattern p = Pattern.compile("Could not find a Java charset equivalent to DB charset (.+).");
            Matcher m = p.matcher(eex.getMessage());

            if (m.matches()) {
                // re-attempt connection, but this time with UTF-8
                // set as the encoding
                runtime.getWarnings().warn(String.format(
                        "Encoding %s is not a known Ruby encoding for %s\n",
                        m.group(1), RUBY_MODULE_NAME));
                setEncodingProperty(props, UTF8_ENCODING);
                API.setInstanceVariable(connection,
                        "@encoding", runtime.newString(UTF8_ENCODING));
                conn = DriverManager.getConnection(url, props);
            } else {
                throw eex;
            }
        }
        return conn;
    }

    /**
     *
     * @param connectionUri
     * @return
     */
    @Override
    public String getJdbcUri(URI connectionUri) {
      String jdbcUri = connectionUri.toString();
      if (jdbcUri.contains("@")) {
          jdbcUri = connectionUri.toString().replaceFirst("://.*@", "://");
      }

      // Replace . with : in scheme name - necessary for scheme jtds.sqlserver
      // : cannot be used in JDBC_URI_SCHEME as then it is identified as opaque URI
      jdbcUri = jdbcUri.replaceFirst("^([a-z]+)(\\.)", "$1:");

      if (!jdbcUri.startsWith("jdbc:")) {
          jdbcUri = "jdbc:" + jdbcUri;
      }
      return jdbcUri;
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
        return sql.replaceFirst("[?]", "'" + param + "'");
    }

    /**
     *
     * @param s
     * @return
     */
    @Override
    public String statementToString(Statement s) {
        try {
            Class<?> psClazz = Class.forName("net.sourceforge.jtds.jdbc.JtdsPreparedStatement");
            Class<?> piClazz = Class.forName("net.sourceforge.jtds.jdbc.ParamInfo");
            Field sqlField = psClazz.getDeclaredField("sql");
            sqlField.setAccessible(true);
            String sql = sqlField.get(s).toString();
            Field paramsField = psClazz.getDeclaredField("parameters");
            paramsField.setAccessible(true);
            Field jdbcTypeField = piClazz.getDeclaredField("jdbcType");
            jdbcTypeField.setAccessible(true);
            Field valueField = piClazz.getDeclaredField("value");
            valueField.setAccessible(true);

            // Appended by jTDS Driver appends to support returning generated
            // keys. Strip for debugging output.
            sql = sql.replace(" SELECT SCOPE_IDENTITY() AS ID", "");
            sql = sql.replace(" SELECT @@IDENTITY AS ID", "");

            Object[] params = (Object[]) paramsField.get(s);
            for (Object param : params) {
                int jdbcType = jdbcTypeField.getInt(param);
                Object value = valueField.get(param);

                switch (jdbcType) {
                    case Types.CHAR:
                    case Types.LONGVARCHAR:
                    case Types.VARCHAR:
                        sql = replace(sql, value.toString());
                    default:
                        sql = replace(sql, value);
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
     * For execution of session initialization SQL statements
     *
     * @param conn
     * @param sql
     * @throws SQLException
     */
    private void exec(Connection conn, String sql)
            throws SQLException {
        Statement s = null;
        try {
            s = conn.createStatement();
            s.execute(sql);
        } finally {
            JDBCUtil.close(s);
        }
    }

}
