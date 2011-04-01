package do_oracle;

import java.io.IOException;
import java.lang.reflect.Field;
import java.net.URI;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleTypes;

import java.util.Properties;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.jruby.Ruby;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.RubyString;

import data_objects.RubyType;
import data_objects.drivers.AbstractDriverDefinition;
import data_objects.util.JDBCUtil;

public class OracleDriverDefinition extends AbstractDriverDefinition {

    public final static String URI_SCHEME = "oracle";
    // . will be replaced with : in Connection.java before connection
    public final static String JDBC_URI_SCHEME = "oracle.thin";
    public final static String RUBY_MODULE_NAME = "Oracle";
    public final static String JDBC_DRIVER = "oracle.jdbc.OracleDriver";

    /**
     *
     */
    public OracleDriverDefinition() {
        super(URI_SCHEME, JDBC_URI_SCHEME, RUBY_MODULE_NAME, JDBC_DRIVER);
    }

    /**
     *
     * @param type
     * @param precision
     * @param scale
     * @return
     */
    @Override
    public RubyType jdbcTypeToRubyType(int type, int precision, int scale) {
        RubyType primitiveType;
        switch (type) {
        case OracleTypes.DATE:
            primitiveType = RubyType.TIME;
            break;
        case OracleTypes.TIMESTAMP:
        case OracleTypes.TIMESTAMPTZ:
        case OracleTypes.TIMESTAMPLTZ:
            primitiveType = RubyType.TIME;
            break;
        case OracleTypes.NUMBER:
            if (precision == 1 && scale == 0)
                primitiveType = RubyType.TRUE_CLASS;
            else if (precision > 1 && scale == 0)
                primitiveType = RubyType.INTEGER;
            else
                primitiveType = RubyType.BIG_DECIMAL;
            break;
        case OracleTypes.BINARY_FLOAT:
        case OracleTypes.BINARY_DOUBLE:
            primitiveType = RubyType.FLOAT;
            break;
        default:
            return super.jdbcTypeToRubyType(type, precision, scale);
        }
        return primitiveType;
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
        case TIME:
            switch (rs.getMetaData().getColumnType(col)) {
            case OracleTypes.DATE:
            case OracleTypes.TIMESTAMP:
            case OracleTypes.TIMESTAMPTZ:
            case OracleTypes.TIMESTAMPLTZ:
                java.sql.Timestamp dt = rs.getTimestamp(col);
                if (dt == null) {
                    return runtime.getNil();
                }
                return prepareRubyTimeFromSqlTime(runtime, sqlTimestampToDateTime(dt));
            default:
                String str = rs.getString(col);
                if (str == null) {
                    return runtime.getNil();
                }
                RubyString return_str = newUnicodeString(runtime, str);
                return_str.setTaint(true);
                return return_str;
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
            ps.setNull(idx, Types.NULL);
            break;
        default:
            super.setPreparedStatementParam(ps, arg, idx);
        }
    }

    /**
     *
     * @param sqlText
     * @param ps
     * @param idx
     * @return
     * @throws SQLException
     */
    @Override
    public boolean registerPreparedStatementReturnParam(String sqlText, PreparedStatement ps, int idx) throws SQLException {
        OraclePreparedStatement ops = (OraclePreparedStatement) ps;
        Pattern p = Pattern.compile("^\\s*INSERT.+RETURNING.+INTO\\s+", Pattern.CASE_INSENSITIVE);
        Matcher m = p.matcher(sqlText);
        if (m.find()) {
            ops.registerReturnParameter(idx, Types.BIGINT);
            return true;
        }
        return false;
    }

    /**
     *
     * @param ps
     * @return
     * @throws SQLException
     */
    @Override
    public long getPreparedStatementReturnParam(PreparedStatement ps) throws SQLException {
        OraclePreparedStatement ops = (OraclePreparedStatement) ps;
        ResultSet rs = ops.getReturnResultSet();
        try {
            if (rs.next()) {
                // Assuming that primary key will not be larger as long max value
                return rs.getLong(1);
            }
            return 0;
        } finally {
            JDBCUtil.close(rs);
        }
    }

    /**
     *
     * @param sqlText
     * @param args
     * @return
     */
    @Override
    public String prepareSqlTextForPs(String sqlText, IRubyObject[] args) {
        String newSqlText = sqlText.replaceFirst(":insert_id", "?");
        return newSqlText;
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
     *
     * @return
     */
    @Override
    public boolean supportsJdbcScrollableResultSets() {
        // when set to true then getDouble and getBigDecimal is failing on BINARY_DOUBLE and BINARY_FLOAT columns
        return false;
    }

    /**
     *
     * @return
     */
    @Override
    public boolean supportsConnectionEncodings()
    {
        return false;
    }

    /**
     *
     * @return
     */
    @Override
    public Properties getDefaultConnectionProperties() {
        Properties props = new Properties();
        // Set prefetch rows to 100 to increase fetching performance SELECTs with many rows
        props.put("defaultRowPrefetch", "100");
        // TODO: should clarify if this is needed for faster performance
        // props.put("SetFloatAndDoubleUseBinary", "true");
        return props;
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

      // Replace . with : in scheme name - necessary for Oracle scheme oracle:thin
      // : cannot be used in JDBC_URI_SCHEME as then it is identified as opaque URI
      jdbcUri = jdbcUri.replaceFirst("^([a-z]+)(\\.)", "$1:");

      // Replace :// with :@// as @ is required in Oracle JDBC connect string
      jdbcUri = jdbcUri.replaceFirst("://", ":@//");

      // Remove options after ?
      jdbcUri = jdbcUri.replaceFirst("\\?.*$", "");

      if (!jdbcUri.startsWith("jdbc:")) {
          jdbcUri = "jdbc:" + jdbcUri;
      }
      return jdbcUri;
    }

    /**
     *
     * @param doConn
     * @param conn
     * @param query
     * @throws SQLException
     */
    @Override
    public void afterConnectionCallback(IRubyObject doConn, Connection conn, Map<String, String> query)
            throws SQLException {
        exec(conn, "alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS'");
        exec(conn, "alter session set nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS.FF'");
        exec(conn, "alter session set nls_timestamp_tz_format = 'YYYY-MM-DD HH24:MI:SS.FF TZH:TZM'");
        String time_zone = null;
        if (query != null)
            time_zone = query.get("time_zone");
        if (time_zone == null)
            time_zone = System.getenv("TZ");
        if (time_zone != null)
            exec(conn, "alter session set time_zone = '"+time_zone+"'");
    }

    /**
     *
     * @param s
     * @return
     */
    @Override
    public String statementToString(Statement s) {
        // String sqlText = ((oracle.jdbc.driver.OraclePreparedStatement) s).getOriginalSql();
        // in ojdbc5 need to retrieve statement field at first
        Statement s2 = (Statement) getFieldValue(s, "statement");
        if (s2 == null)
            s2 = s;
        String sqlText = (String) getFieldValue(getFieldValue(s2, "sqlObject"), "originalSql");
        // ParameterMetaData md = ps.getParameterMetaData();
        return sqlText;
    }

    /**
     *
     * @param obj
     * @param field
     * @return
     */
    private Object getFieldValue(Object obj, String field) {
        Class c = obj.getClass();
        while (c != null) {
            try {
                Field f = c.getDeclaredField(field);
                f.setAccessible(true);
                return f.get(obj);
            } catch (NoSuchFieldException e) {
                c = c.getSuperclass();
            } catch (IllegalAccessException e) {
                return null;
            }
        }
        return null;
    }

    /**
     *  For execution of session initialization SQL statements
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
