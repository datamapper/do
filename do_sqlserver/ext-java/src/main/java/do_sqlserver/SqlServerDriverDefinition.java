package do_sqlserver;

import java.io.IOException;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import java.util.Properties;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.jruby.Ruby;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.RubyString;

import org.joda.time.DateTime;

import data_objects.RubyType;
import data_objects.drivers.AbstractDriverDefinition;

public class SqlServerDriverDefinition extends AbstractDriverDefinition {

    public final static String URI_SCHEME = "sqlserver";
    // . will be replaced with : in Connection.java before connection
    public final static String JDBC_URI_SCHEME = "jdts.sqlserver";
    public final static String RUBY_MODULE_NAME = "SqlServer";

    public SqlServerDriverDefinition() {
        super(URI_SCHEME, JDBC_URI_SCHEME, RUBY_MODULE_NAME);
    }

    @Override
    public RubyType jdbcTypeToRubyType(int type, int precision, int scale) {
        RubyType primitiveType;
        switch (type) {
//        case SqlServerTypes.DATE:
//            primitiveType = RubyType.TIME;
//            break;
//        case SqlServerTypes.TIMESTAMP:
//        case SqlServerTypes.TIMESTAMPTZ:
//        case SqlServerTypes.TIMESTAMPLTZ:
//            primitiveType = RubyType.TIME;
//            break;
//        case SqlServerTypes.NUMBER:
//            if (precision == 1 && scale == 0)
//                primitiveType = RubyType.TRUE_CLASS;
//            else if (precision > 1 && scale == 0)
//                primitiveType = RubyType.INTEGER;
//            else
//                primitiveType = RubyType.BIG_DECIMAL;
//            break;
//        case SqlServerTypes.BINARY_FLOAT:
//        case SqlServerTypes.BINARY_DOUBLE:
//            primitiveType = RubyType.FLOAT;
//            break;
        default:
            return super.jdbcTypeToRubyType(type, precision, scale);
        }
        //return primitiveType;
    }

    @Override
    protected IRubyObject doGetTypecastResultSetValue(Ruby runtime,
            ResultSet rs, int col, RubyType type) throws SQLException,
            IOException {
        switch (type) {
        case TIME:
            switch (rs.getMetaData().getColumnType(col)) {
//            case SqlServerTypes.DATE:
//            case SqlServerTypes.TIMESTAMP:
//            case SqlServerTypes.TIMESTAMPTZ:
//            case SqlServerTypes.TIMESTAMPLTZ:
//                java.sql.Timestamp dt = null;
//                try {
//                    dt = rs.getTimestamp(col);
//                } catch (SQLException sqle) {
//                }
//                if (dt == null) {
//                    return runtime.getNil();
//                }
//                return prepareRubyTimeFromSqlTime(runtime, new DateTime(dt));
            default:
                String str = rs.getString(col);
                if (str == null) {
                    return runtime.getNil();
                }
                RubyString return_str = RubyString.newUnicodeString(runtime,
                        str);
                return_str.setTaint(true);
                return return_str;
            }
        default:
            return super.doGetTypecastResultSetValue(runtime, rs, col, type);
        }
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
    public boolean supportsJdbcGeneratedKeys() {
        return true;
    }

    @Override
    public boolean supportsJdbcScrollableResultSets() {
        return true;
    }

   // @Override
   // public String prepareSqlTextForPs(String sqlText, IRubyObject[] args) {
   //     String newSqlText = sqlText.replaceFirst(":insert_id", "?");
   //     return newSqlText;
   // }

    @Override
    public String statementToString(Statement s) {
        //try {
            String sqlText = (s).toString();
            // ParameterMetaData md = ps.getParameterMetaData();
            return sqlText;
        //} catch (SQLException sqle) {
        //    return "(exception in getOriginalSql)";
        //}
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
