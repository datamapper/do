package do_sqlite3;

import java.io.IOException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import org.joda.time.DateTime;
import org.jruby.Ruby;
import org.jruby.RubyBigDecimal;
import org.jruby.RubyFloat;
import org.jruby.RubyTime;
import org.jruby.runtime.builtin.IRubyObject;

import data_objects.RubyType;
import data_objects.drivers.AbstractDriverDefinition;

public class Sqlite3DriverDefinition extends AbstractDriverDefinition {

    public final static String URI_SCHEME = "sqlite3";
    public final static String JDBC_URI_SCHEME = "sqlite";
    public final static String RUBY_MODULE_NAME = "Sqlite3";

    public Sqlite3DriverDefinition() {
        super(URI_SCHEME, JDBC_URI_SCHEME, RUBY_MODULE_NAME);
    }

    @Override
    protected IRubyObject doGetTypecastResultSetValue(Ruby runtime,
            ResultSet rs, int col, RubyType type) throws SQLException,
            IOException {
        switch (type) {
        case DATE:
            DateTime date = toDate(rs.getString(col));
            if (date == null) {
                return runtime.getNil();
            }
            return prepareRubyDateFromSqlDate(runtime, date);
        case DATE_TIME:
            DateTime dt = toTimestamp(rs.getString(col));
            if (dt == null) {
                return runtime.getNil();
            }
            return prepareRubyDateTimeFromSqlTimestamp(runtime, dt);
        case TIME:
            switch (rs.getMetaData().getColumnType(col)) {
            case Types.TIME:
                DateTime tm = toTime(rs.getString(col));
                if (tm == null) {
                    return runtime.getNil();
                }
                return prepareRubyTimeFromSqlTime(runtime, tm);
            case Types.TIMESTAMP:
                DateTime ts = toTime(rs.getString(col));
                if (ts == null) {
                    return runtime.getNil();
                }
                return prepareRubyTimeFromSqlTime(runtime, ts);
            case Types.DATE:
                java.sql.Date da = rs.getDate(col);
                if (da == null) {
                    return runtime.getNil();
                }
                return prepareRubyTimeFromSqlDate(runtime, da);
            default:
                DateTime time = toTime(rs.getString(col));
                if (time == null) {
                    return runtime.getNil();
                }
                return prepareRubyTimeFromSqlTime(runtime, time);
            }
        case FLOAT:
            return new RubyFloat(runtime, new java.math.BigDecimal(rs
                    .getString(col)).doubleValue());
        case BIG_DECIMAL:
            return new RubyBigDecimal(runtime, new java.math.BigDecimal(rs
                    .getString(col)));
        default:
            return super.doGetTypecastResultSetValue(runtime, rs, col, type);
        }
    }

    @Override
    public void setPreparedStatementParam(PreparedStatement ps,
            IRubyObject arg, int idx) throws SQLException {
        switch (RubyType.getRubyType(arg.getType().getName())) {
        case BIG_DECIMAL:
            ps.setString(idx, ((RubyBigDecimal) arg).toString());
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
            String time = ((RubyTime) arg).getDateTime().toString(
                    "yyyy-MM-dd'T'HH:mm:ssZZ");
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

    @Override
    public boolean supportsJdbcGeneratedKeys() {
        return true;
    }

    @Override
    public boolean supportsJdbcScrollableResultSets() {
        return false; // TODO
    }

    @Override
    public boolean supportsConnectionPrepareStatementMethodWithGKFlag() {
        return false;
    }

    @Override
    public String quoteString(String str) {
        StringBuffer quotedValue = new StringBuffer(str.length() + 2);
        quotedValue.append("\'");
        quotedValue.append(str.replaceAll("'", "''"));
        quotedValue.append("\'");
        return quotedValue.toString();
    }

}
