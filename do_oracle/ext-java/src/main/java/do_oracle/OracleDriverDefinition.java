package do_oracle;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.Properties;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleTypes;
import java.sql.ParameterMetaData;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.jruby.Ruby;
import org.jruby.runtime.builtin.IRubyObject;

import data_objects.RubyType;
import data_objects.drivers.AbstractDriverDefinition;

public class OracleDriverDefinition extends AbstractDriverDefinition {

    public final static String URI_SCHEME = "oracle";
    // . will be replaced with : in Connection.java before connection
    public final static String JDBC_URI_SCHEME = "oracle.thin";
    public final static String RUBY_MODULE_NAME = "Oracle";

    public OracleDriverDefinition() {
        super(URI_SCHEME, JDBC_URI_SCHEME, RUBY_MODULE_NAME);
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
            try {
                rs.close();
            } catch (Exception e) {}
        }
    }

    @Override
    public String prepareSqlTextForPs(String sqlText, IRubyObject[] args) {
        String newSqlText = sqlText.replaceFirst(":insert_id", "?");
        return newSqlText;
    }

    @Override
    public boolean supportsJdbcGeneratedKeys()
    {
        return false;
    }

    @Override
    public boolean supportsJdbcScrollableResultSets() {
        // when set to true then getDouble and getBigDecimal is failing on BINARY_DOUBLE and BINARY_FLOAT columns
        return false;
    }

    @Override
    public boolean supportsConnectionEncodings()
    {
        return false;
    }

    @Override
    public Properties getDefaultConnectionProperties() {
        Properties props = new Properties();
        // Set prefetch rows to 100 to increase fetching performance SELECTs with many rows
        props.put("defaultRowPrefetch", "100");
        // TODO: should clarify if this is needed for faster performance
        // props.put("SetFloatAndDoubleUseBinary", "true");
        return props;
    }

    @Override
    public void afterConnectionCallback(Connection conn)
            throws SQLException {
        exec(conn, "alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS'");
        exec(conn, "alter session set nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS.FF'");
        exec(conn, "alter session set nls_timestamp_tz_format = 'YYYY-MM-DD HH24:MI:SS.FF TZH:TZM'");
    }

    @Override
    public String toString(PreparedStatement ps) {
        try {
            String sqlText = ((oracle.jdbc.driver.OracleStatement) ps).getOriginalSql();
            // ParameterMetaData md = ps.getParameterMetaData();
            return sqlText;
        } catch (SQLException sqle) {
            return "(exception in getOriginalSql)";
        }
    }

    // for execution of session initialization SQL statements
    private void exec(Connection conn, String sql)
            throws SQLException {
        Statement s = null;
        try {
            s = conn.createStatement();
            s.execute(sql);
        } finally {
            if (s != null) {
                try {
                    s.close();
                } catch (SQLException sqle2) {
                }
            }
        }
    }

}
