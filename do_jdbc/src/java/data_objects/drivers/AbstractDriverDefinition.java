package data_objects.drivers;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URISyntaxException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.GregorianCalendar;
import java.util.Iterator;
import java.util.Map;
import java.util.Properties;
import java.util.TimeZone;

import org.jruby.Ruby;
import org.jruby.RubyBigDecimal;
import org.jruby.RubyBignum;
import org.jruby.RubyClass;
import org.jruby.RubyFloat;
import org.jruby.RubyHash;
import org.jruby.RubyNumeric;
import org.jruby.RubyObjectAdapter;
import org.jruby.RubyProc;
import org.jruby.RubyString;
import org.jruby.RubyTime;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.marshal.UnmarshalStream;
import org.jruby.util.ByteList;

import data_objects.DataObjectsUtils;
import data_objects.RubyType;

/**
 * 
 * @author alexbcoles
 */
public abstract class AbstractDriverDefinition implements DriverDefinition {

    protected static final RubyObjectAdapter api = JavaEmbedUtils
            .newObjectAdapter();

    private final String scheme;
    private final String moduleName;

    protected AbstractDriverDefinition(String scheme, String moduleName) {
        this.scheme = scheme;
        this.moduleName = moduleName;
    }

    public String getModuleName() {
        return this.moduleName;
    }

    public String getErrorName() {
        return this.moduleName + "Error";
    }

    @SuppressWarnings("unchecked")
    public final URI parseConnectionURI(IRubyObject connection_uri)
            throws URISyntaxException, UnsupportedEncodingException {
        URI uri;

        if ("DataObjects::URI".equals(connection_uri.getType().getName())) {
            String query = null;
            StringBuffer userInfo = new StringBuffer();

            verifyScheme(DataObjectsUtils.stringOrNull(api.callMethod(
                    connection_uri, "scheme")));

            String user = DataObjectsUtils.stringOrNull(api.callMethod(
                    connection_uri, "user"));
            String password = DataObjectsUtils.stringOrNull(api.callMethod(
                    connection_uri, "password"));
            String host = DataObjectsUtils.stringOrNull(api.callMethod(
                    connection_uri, "host"));
            int port = DataObjectsUtils.intOrMinusOne(api.callMethod(
                    connection_uri, "port"));
            String path = DataObjectsUtils.stringOrNull(api.callMethod(
                    connection_uri, "path"));
            IRubyObject query_values = api.callMethod(connection_uri, "query");
            String fragment = DataObjectsUtils.stringOrNull(api.callMethod(
                    connection_uri, "fragment"));

            if (user != null && !"".equals(user)) {
                userInfo.append(user);
                if (password != null && !"".equals(password)) {
                    userInfo.append(":").append(password);
                }
            }

            if (query_values.isNil()) {
                query = null;
            } else if (query_values instanceof RubyHash) {
                query = mapToQueryString(query_values.convertToHash());
            } else {
                query = api.callMethod(query_values, "to_s").asJavaString();
            }

            if (host != null && !"".equals(host)) {
                // a client/server database (e.g. MySQL, PostgreSQL, MS
                // SQLServer)
                uri = new URI(this.scheme, userInfo.toString(), host, port,
                        path, query, fragment);
            } else {
                // an embedded / file-based database (e.g. SQLite3, Derby
                // (embedded mode), HSQLDB - use opaque uri
                uri = new java.net.URI(scheme, path, fragment);
            }
        } else {
            // If connection_uri comes in as a string, we just pass it
            // through
            uri = new URI(connection_uri.asJavaString());
        }
        return uri;
    }

    protected void verifyScheme(String scheme) {
        if (!this.scheme.equals(scheme)) {
            throw new RuntimeException("scheme mismatch, expected: "
                    + this.scheme + " but got: " + scheme);
        }
    }

    /**
     * Convert a map of key/values to a URI query string
     * 
     * @param map
     * @return
     * @throws java.io.UnsupportedEncodingException
     */
    private String mapToQueryString(Map<Object, Object> map)
            throws UnsupportedEncodingException {
        Iterator it = map.entrySet().iterator();
        StringBuffer querySb = new StringBuffer();
        while (it.hasNext()) {
            Map.Entry pairs = (Map.Entry) it.next();
            String key = (pairs.getKey() != null) ? pairs.getKey().toString()
                    : "";
            String value = (pairs.getValue() != null) ? pairs.getValue()
                    .toString() : "";
            querySb.append(java.net.URLEncoder.encode(key, "UTF-8"))
                    .append("=");
            querySb.append(java.net.URLEncoder.encode(value, "UTF-8"));
        }
        return querySb.toString();
    }
    public RaiseException newDriverError(Ruby runtime,
            String message) {
        RubyClass driverError = runtime.getClass(getErrorName());
        return new RaiseException(runtime, driverError, message, true);
    }

    public RaiseException newDriverError(Ruby runtime, SQLException exception) {
       return newDriverError(runtime, exception, null);
    }

    public RaiseException newDriverError(Ruby runtime,
            SQLException exception, java.sql.Statement statement)
    {
        RubyClass driverError = runtime.getClass(getErrorName());
        int code = exception.getErrorCode();
        StringBuffer sb = new StringBuffer("(");

        // Append the Vendor Code, if there is one
        // TODO: parse vendor exception codes
        // TODO: replace 'vendor' with vendor name
        if (code > 0) sb.append("vendor_errno=").append(code).append(", ");
        sb.append("sql_state=").append(exception.getSQLState()).append(") ");
        sb.append(exception.getLocalizedMessage());
        // TODO: delegate to the DriverDefinition for this
        if (statement != null) sb.append("\nQuery: ").append(statement.toString());

        return new RaiseException(runtime, driverError, sb.toString(), true);
    }

    public RubyObjectAdapter getObjectAdapter() {
        return api;
    }
    public final IRubyObject getTypecastResultSetValue(Ruby runtime,
            ResultSet rs, int col, RubyType type) throws SQLException,
            IOException {
        // TODO assert to needs to be turned on with the java call
        // better throw something
        assert (type != null); // this method does not expect a null Ruby Type
        if (rs == null) {// || rs.wasNull()) {
            return runtime.getNil();
        }

        return doGetTypecastResultSetValue(runtime, rs, col, type);
    }

    protected IRubyObject doGetTypecastResultSetValue(Ruby runtime,
            ResultSet rs, int col, RubyType type) throws SQLException,
            IOException {
        switch (type) {
        case FIXNUM:
        case INTEGER:
        case BIGNUM:
            // TODO: attempt to make this more granular, depending on the
            // size of the number (?)
            long lng = rs.getLong(col);
            return RubyNumeric.int2fix(runtime, lng);
        case FLOAT:
            return new RubyFloat(runtime, rs.getBigDecimal(col).doubleValue());
        case BIG_DECIMAL:
            return new RubyBigDecimal(runtime, rs.getBigDecimal(col));
        case DATE:
            java.sql.Date date = rs.getDate(col);
            if (date == null) {
                return runtime.getNil();
            }
            return DataObjectsUtils.prepareRubyDateFromSqlDate(runtime, date);
        case DATE_TIME:
            java.sql.Timestamp dt = null;
            // DateTimes with all-zero components throw a SQLException with
            // SQLState S1009 in MySQL Connector/J 3.1+
            // See
            // http://dev.mysql.com/doc/refman/5.0/en/connector-j-installing-upgrading.html
            try {
                dt = rs.getTimestamp(col);
            } catch (SQLException sqle) {
            }
            if (dt == null) {
                return runtime.getNil();
            }
            return DataObjectsUtils.prepareRubyDateTimeFromSqlTimestamp(
                    runtime, dt);
        case TIME:
            switch (rs.getMetaData().getColumnType(col)) {
            case Types.TIME:
                java.sql.Time tm = rs.getTime(col);
                if (tm == null) {
                    return runtime.getNil();
                }
                return DataObjectsUtils.prepareRubyTimeFromSqlTime(runtime, tm);
            case Types.TIMESTAMP:
                java.sql.Time ts = rs.getTime(col);
                if (ts == null) {
                    return runtime.getNil();
                }
                return DataObjectsUtils.prepareRubyTimeFromSqlTime(runtime, ts);
            case Types.DATE:
                java.sql.Date da = rs.getDate(col);
                if (da == null) {
                    return runtime.getNil();
                }
                return DataObjectsUtils.prepareRubyTimeFromSqlDate(runtime, da);
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
        case TRUE_CLASS:
            boolean bool = rs.getBoolean(col);
            return runtime.newBoolean(bool);
        case BYTE_ARRAY:
            InputStream binaryStream = rs.getBinaryStream(col);
            ByteList bytes = new ByteList(2048);
            try {
                byte[] buf = new byte[2048];
                for (int n = binaryStream.read(buf); n != -1; n = binaryStream
                        .read(buf)) {
                    bytes.append(buf, 0, n);
                }
            } finally {
                binaryStream.close();
            }
            return api.callMethod(runtime.fastGetModule("Extlib").fastGetClass(
                    "ByteArray"), "new", runtime.newString(bytes));
        case CLASS:
            String classNameStr = rs.getString(col);
            if (classNameStr == null) {
                return runtime.getNil();
            }
            RubyString class_name_str = RubyString.newUnicodeString(runtime, rs
                    .getString(col));
            class_name_str.setTaint(true);
            return api.callMethod(runtime.getObject(), "full_const_get",
                    class_name_str);
        case OBJECT:
            InputStream asciiStream = rs.getAsciiStream(col);
            IRubyObject obj = runtime.getNil();
            try {
                UnmarshalStream ums = new UnmarshalStream(runtime, asciiStream,
                        RubyProc.NEVER);
                obj = ums.unmarshalObject();
            } catch (IOException ioe) {
                // TODO: log this
            }
            return obj;
        case NIL:
            return runtime.getNil();
        case STRING:
        default:
            String str = rs.getString(col);
            if (str == null) {
                return runtime.getNil();
            }
            RubyString return_str = RubyString.newUnicodeString(runtime, str);
            return_str.setTaint(true);
            return return_str;
        }
    }

    // TODO SimpleDateFormat is not threadsafe better use joda classes
    // http://java.sun.com/j2se/1.5.0/docs/api/java/text/SimpleDateFormat.html#synchronization
    // http://joda-time.sourceforge.net/api-release/org/joda/time/DateTime.html
    private static final DateFormat FORMAT = new SimpleDateFormat(
            "yyyy-MM-dd HH:mm:ss");

    public void setPreparedStatementParam(PreparedStatement ps,
            IRubyObject arg, int idx) throws SQLException {
        switch (RubyType.getRubyType(arg.getType().getName())) {
        case FIXNUM:
            ps.setInt(idx, Integer.parseInt(arg.toString()));
            break;
        case BIGNUM:
            ps.setLong(idx, ((RubyBignum) arg).getLongValue());
            break;
        case FLOAT:
            ps.setDouble(idx, RubyNumeric.num2dbl(arg));
            break;
        case BIG_DECIMAL:
            ps.setBigDecimal(idx, ((RubyBigDecimal) arg).getValue());
            break;
        case NIL:
            ps.setNull(idx, ps.getParameterMetaData().getParameterType(idx));
            break;
        case TRUE_CLASS:
        case FALSE_CLASS:
            ps.setBoolean(idx, arg.toString().equals("true"));
            break;
        case CLASS:
            ps.setString(idx, arg.toString());
            break;
        case BYTE_ARRAY:
            ps.setBytes(idx, ((RubyString) arg).getBytes());
            break;
        // TODO: add support for ps.setBlob();
        case DATE:
            ps.setDate(idx, java.sql.Date.valueOf(arg.toString()));
            break;
        case TIME:
            RubyTime rubyTime = (RubyTime) arg;
            java.util.Date date = rubyTime.getJavaDate();

            GregorianCalendar cal = new GregorianCalendar();
            cal.setTime(date);
            cal.setTimeZone(TimeZone.getTimeZone("UTC")); // XXX works only if
            // driver suports
            // Calendars in PS
            java.sql.Timestamp ts;
            if (supportsCalendarsInJDBCPreparedStatement() == true) {
                ts = new java.sql.Timestamp(cal.getTime().getTime());
                ts.setNanos(cal.get(GregorianCalendar.MILLISECOND) * 100000);
            } else {
                // XXX ugly workaround for MySQL and Hsqldb
                // TODO better use joda
                ts = new Timestamp(cal.get(GregorianCalendar.YEAR) - 1900, cal
                        .get(GregorianCalendar.MONTH), cal
                        .get(GregorianCalendar.DAY_OF_MONTH), cal
                        .get(GregorianCalendar.HOUR_OF_DAY), cal
                        .get(GregorianCalendar.MINUTE), cal
                        .get(GregorianCalendar.SECOND), cal
                        .get(GregorianCalendar.MILLISECOND) * 100000);
            }
            ps.setTimestamp(idx, ts, cal);
            break;
        case DATE_TIME:
            String datetime = arg.toString().replace('T', ' ');
            ps.setTimestamp(idx, java.sql.Timestamp.valueOf(datetime
                    .replaceFirst("[-+]..:..$", "")));
            break;
        default:
            if (arg.toString().indexOf("-") != -1
                    && arg.toString().indexOf(":") != -1) {
                // TODO: improve the above string pattern checking
                // Handle date patterns in strings
                java.util.Date parsedDate;
                try {
                    parsedDate = FORMAT.parse(arg.asJavaString().replace('T',
                            ' '));
                    java.sql.Timestamp timestamp = new java.sql.Timestamp(
                            parsedDate.getTime());
                    ps.setTimestamp(idx, timestamp);
                } catch (ParseException ex) {
                    ps.setString(idx, api.convertToRubyString(arg)
                            .getUnicodeValue());
                }
            } else if (arg.toString().indexOf(":") != -1
                    && arg.toString().length() == 8) {
                // Handle time patterns in strings
                ps.setTime(idx, java.sql.Time.valueOf(arg.asJavaString()));
            } else {
                Integer jdbcTypeId = null;
                try {
                    jdbcTypeId = ps.getMetaData().getColumnType(idx);
                } catch (Exception ex) {
                }

                if (jdbcTypeId == null) {
                    ps.setString(idx, api.convertToRubyString(arg)
                            .getUnicodeValue());
                } else {
                    // TODO: Here comes conversions like '.execute_reader("2")'
                    // It definitly needs to be refactored...
                    try {
                        if (jdbcTypeId == Types.VARCHAR) {
                            ps.setString(idx, api.convertToRubyString(arg)
                                    .getUnicodeValue());
                        } else if (jdbcTypeId == Types.INTEGER) {
                            ps.setObject(idx, Integer.valueOf(arg.toString()),
                                    jdbcTypeId);
                        } else {
                            // I'm not sure is it correct in 100%
                            ps.setString(idx, api.convertToRubyString(arg)
                                    .getUnicodeValue());
                        }
                    } catch (NumberFormatException ex) { // i.e
                        // Integer.valueOf
                        ps.setString(idx, api.convertToRubyString(arg)
                                .getUnicodeValue());
                    }
                }
            }
        }
    }

    public abstract boolean supportsJdbcGeneratedKeys();

    public abstract boolean supportsJdbcScrollableResultSets();

    public boolean supportsConnectionEncodings() {
        return false;
    }

    public boolean supportsConnectionPrepareStatementMethodWithGKFlag() {
        return true;
    }

    public boolean supportsCalendarsInJDBCPreparedStatement(){
        return true;
    }

    public ResultSet getGeneratedKeys(Connection connection) {
        return null;
    }

    public Properties getDefaultConnectionProperties() {
        return new Properties();
    }

    public void setEncodingProperty(Properties props, String encodingName) {
        // do nothing
    }

    public String quoteString(String str) {
        StringBuffer quotedValue = new StringBuffer(str.length() + 2);
        quotedValue.append("\'");
        quotedValue.append(str);
        quotedValue.append("\'");
        return quotedValue.toString();
    }

    public String toString(PreparedStatement ps) {
        return ps.toString();
    }

}
