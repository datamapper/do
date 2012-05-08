package do_sqlite3;

import java.lang.reflect.Field;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.joda.time.DateTime;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;
import org.joda.time.format.ISODateTimeFormat;
import org.jruby.Ruby;
import org.jruby.RubyBignum;
import org.jruby.RubyNumeric;
import org.jruby.RubyFloat;
import org.jruby.RubyTime;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;

import data_objects.RubyType;
import data_objects.drivers.AbstractDriverDefinition;

public class Sqlite3DriverDefinition extends AbstractDriverDefinition {

    private final static DateTimeFormatter TIMESTAMP_ZONE_FORMAT = DateTimeFormat.forPattern("yyyy-MM-dd'T'HH:mm:ssZ");
    private final static DateTimeFormatter TIMESTAMP_FORMAT = DateTimeFormat.forPattern("yyyy-MM-dd'T'HH:mm:ss");
    private final static DateTimeFormatter DATE_FORMAT = ISODateTimeFormat.date();// yyyy-MM-dd

    public final static String URI_SCHEME = "sqlite3";
    public final static String JDBC_URI_SCHEME = "sqlite";
    public final static String RUBY_MODULE_NAME = "Sqlite3";
    public final static String JDBC_DRIVER = "org.sqlite.JDBC";

    /**
     *
     */
    public Sqlite3DriverDefinition() {
        super(URI_SCHEME, JDBC_URI_SCHEME, RUBY_MODULE_NAME, JDBC_DRIVER);
    }

    /**
     *
     * @param date
     * @return
     */
    public static java.util.Date toDate(String date) {
        return DATE_FORMAT.parseDateTime(date.replaceFirst("T.*", "")).toDate();
    }

    /**
     *
     * @param stamp
     * @return
     */
    public static DateTime toTimestamp(String stamp) {
        DateTimeFormatter formatter;
        // just allow string with T or without, allow strings with zone part or without
        if (stamp.contains("T") || stamp.trim().contains(" ")) {
            stamp = stamp.trim().replace(" ", "T");
            if (stamp.matches(".*[-+]..:..$")) {
                formatter = TIMESTAMP_ZONE_FORMAT;// "yyyy-MM-dd HH:mm:ssZ"
            }
            else {
                formatter = TIMESTAMP_FORMAT;// "yyyy-MM-dd HH:mm:ssZ"
            }
        }
        else {
            formatter = DATE_FORMAT; // "yyyy-MM-dd"
        }

        return formatter.parseDateTime(stamp);
    }

    /**
     *
     * @param time
     * @return
     */
    public static DateTime toTime(String time) {
        DateTimeFormatter formatter = time.contains(" ") ? DATE_TIME_FORMAT : (time.contains("T") ? TIMESTAMP_FORMAT : DATE_FORMAT);
        return formatter.parseDateTime(time);
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
        // System.out.println(rs.getMetaData().getColumnTypeName(col) + " = " + type.toString());
        switch (type) {
        case DATE:
            String date = rs.getString(col);
            if (date == null) {
                return runtime.getNil();
            }
            return prepareRubyDateFromSqlDate(runtime, toDate(date));
        case DATE_TIME:
            String dt = rs.getString(col);
            if (dt == null) {
                return runtime.getNil();
            }
            return prepareRubyDateTimeFromSqlTimestamp(runtime, toTimestamp(dt));
        case TIME:
            String time = rs.getString(col);
            if (time == null) {
                return runtime.getNil();
            }
            return prepareRubyTimeFromSqlTime(runtime, toTimestamp(time));
        case FIXNUM:
        case INTEGER:
        case BIGNUM:
            try {
                // in most cases integers will fit into long type
                // and therefore should be faster to use getLong
                long lng = rs.getLong(col);
                if (rs.wasNull()) {
                    return runtime.getNil();
                }
                return RubyNumeric.int2fix(runtime, lng);
            } catch (SQLException sqle) {
                // as SQLite JDBC driver has not implemented getBigDecimal we need to get as String
                String ivalue = rs.getString(col);
                if (ivalue == null) {
                    return runtime.getNil();
                }
                // will return either Fixnum or Bignum
                return RubyBignum.bignorm(runtime, (new BigDecimal(ivalue)).toBigInteger());
            }
        case FLOAT:
            String fvalue = rs.getString(col);
            if (fvalue == null) {
                return runtime.getNil();
            }
            return new RubyFloat(runtime, new BigDecimal(fvalue).doubleValue());
        case BIG_DECIMAL:
            String dvalue = rs.getString(col);
            if (dvalue == null) {
                return runtime.getNil();
            }
            return runtime.getKernel().callMethod("BigDecimal",
                    runtime.newString(dvalue));
        case BYTE_ARRAY:
            ByteList bytes = new ByteList(rs.getBytes(col));
            if (rs.wasNull() || bytes.length() == 0) {
                return runtime.getNil();
            }
            return API.callMethod(runtime.fastGetModule("Extlib").fastGetClass(
                    "ByteArray"), "new", runtime.newString(bytes));
        case TRUE_CLASS:
            final String tvalue = rs.getString(col);
            if (tvalue == null) {
                return runtime.getNil();
            }
            return runtime.newBoolean("t".equals(tvalue));
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
        case BIG_DECIMAL:
            ps.setString(idx, ((BigDecimal) arg.toJava(Object.class)).toPlainString());
            break;
        case TRUE_CLASS:
            ps.setString(idx, "t");
            break;
        case FALSE_CLASS:
            ps.setString(idx, "f");
            break;
        case DATE_TIME:
            String datetime = arg.toString();
            ps.setString(idx, datetime);
            break;
        case TIME:
            String time = ((RubyTime) arg).getDateTime().toString("yyyy-MM-dd'T'HH:mm:ssZZ");
            ps.setString(idx, time);
            break;
        case DATE:
            String date = arg.toString();
            ps.setString(idx, date);
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
    public boolean supportsJdbcGeneratedKeys() {
        return true;
    }

    /**
     *
     * @return
     */
    @Override
    public boolean supportsJdbcScrollableResultSets() {
        return false; // TODO
    }

    /**
     *
     * @return
     */
    @Override
    public boolean supportsConnectionPrepareStatementMethodWithGKFlag() {
        return false;
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
            Class<?> c = Class.forName("org.sqlite.Stmt");
            Field sqlField = c.getDeclaredField("sql");
            sqlField.setAccessible(true);
            String sql = sqlField.get(s).toString();
            Field batchField = c.getDeclaredField("batch");
            batchField.setAccessible(true);
            Object[] batch = (Object[]) batchField.get(s);
            for (Object param : batch) {
                if (param instanceof String)
                    sql = replace(sql, param.toString());
                else
                    sql = replace(sql, param);
            }
            return sql;
        }
        catch(Exception e) {
            // just fall to the toString of the PreparedStatement
            return s.toString();
        }
    }

}
