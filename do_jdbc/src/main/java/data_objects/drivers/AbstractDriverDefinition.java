package data_objects.drivers;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.net.URI;
import java.net.URISyntaxException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.Driver;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.Calendar;
import java.util.Map;
import java.util.Properties;

import org.jcodings.Encoding;
import org.joda.time.DateTime;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;
import org.jruby.Ruby;
import org.jruby.RubyBignum;
import org.jruby.RubyClass;
import org.jruby.RubyEncoding;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyHash;
import org.jruby.RubyInteger;
import org.jruby.RubyNumeric;
import org.jruby.RubyObjectAdapter;
import org.jruby.RubyRegexp;
import org.jruby.RubyString;
import org.jruby.RubyTime;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;

import data_objects.RubyType;

/**
 *
 * @author alexbcoles
 * @author mkristian
 */
public abstract class AbstractDriverDefinition implements DriverDefinition {

    // assuming that API is thread safe
    protected static final RubyObjectAdapter API = JavaEmbedUtils
            .newObjectAdapter();

    private final static DateTimeFormatter TIMESTAMP_FORMAT = DateTimeFormat.forPattern("yyyy-MM-dd' 'HH:mm:ssZ");
    protected final static DateTimeFormatter DATE_TIME_FORMAT = DateTimeFormat.forPattern("yyyy-MM-dd HH:mm:ss");
    private final static BigInteger LONG_MAX = BigInteger.valueOf(Long.MAX_VALUE);
    private final static BigInteger LONG_MIN = BigInteger.valueOf(Long.MIN_VALUE);

    private final String scheme;
    private final String jdbcScheme;
    private final String moduleName;
    private final Driver driver;

    /**
     *
     * @param scheme
     * @param moduleName
     * @param jdbcDriver
     */
    protected AbstractDriverDefinition(String scheme, String moduleName, String jdbcDriver) {
        this(scheme, scheme, moduleName, jdbcDriver);
    }

    /**
     *
     * @param scheme
     * @param jdbcScheme
     * @param moduleName
     * @param jdbcDriver
     */
    protected AbstractDriverDefinition(String scheme, String jdbcScheme,
            String moduleName, String jdbcDriver) {
        this.scheme = scheme;
        this.jdbcScheme = jdbcScheme;
        this.moduleName = moduleName;
        try {
            this.driver = (Driver)loadClass(jdbcDriver).newInstance();
        }
        catch (InstantiationException e) {
            throw new RuntimeException("should not happen", e);
        }
        catch (IllegalAccessException e) {
            throw new RuntimeException("should not happen", e);
        }
        catch (ClassNotFoundException e) {
            throw new RuntimeException("should not happen", e);
        }
    }

    private Class<?> loadClass(String className)
            throws ClassNotFoundException {
        ClassLoader ccl = Thread.currentThread().getContextClassLoader();
        Class<?> result = null;
        try {
            if (ccl != null) {
                result = ccl.loadClass(className);
            }
        } catch (ClassNotFoundException e) {
            // ignore
        }

        if (result == null) {
            result = getClass().getClassLoader().loadClass(className);
        }

        return result;
    }

    /**
     *
     * @return
     */
    public String getModuleName() {
        return this.moduleName;
    }

    /**
     *
     * @param uri jdbc uri for which a connection is created
     * @param properties further properties needed to create a cconnection, i.e. username + password
     * @return
     * @throws SQLException
     */
    public Connection getConnection(String uri, Properties properties) throws SQLException{
        return driver.connect(uri, properties);
    }

    /**
     *
     * @param connection_uri
     * @return
     * @throws URISyntaxException
     * @throws UnsupportedEncodingException
     */
    @SuppressWarnings("unchecked")
    public URI parseConnectionURI(IRubyObject connection_uri)
            throws URISyntaxException, UnsupportedEncodingException {
        URI uri;

        if ("DataObjects::URI".equals(connection_uri.getType().getName())) {
            String query;
            StringBuilder userInfo = new StringBuilder();

            verifyScheme(stringOrNull(API.callMethod(connection_uri, "scheme")));

            String user = stringOrNull(API.callMethod(connection_uri, "user"));
            String password = stringOrNull(API.callMethod(connection_uri,
                    "password"));
            String host = stringOrNull(API.callMethod(connection_uri, "host"));
            int port = intOrMinusOne(API.callMethod(connection_uri, "port"));
            String path = stringOrNull(API.callMethod(connection_uri, "path"));
            IRubyObject query_values = API.callMethod(connection_uri, "query");
            String fragment = stringOrNull(API.callMethod(connection_uri,
                    "fragment"));

            if (user != null && !"".equals(user)) {
                userInfo.append(user);
                if (password != null) {
                    userInfo.append(":").append(password);
                }
            }

            if (query_values.isNil()) {
                query = null;
            } else if (query_values instanceof RubyHash) {
                query = mapToQueryString(query_values.convertToHash());
            } else {
                query = API.callMethod(query_values, "to_s").asJavaString();
            }

            if (host != null && !"".equals(host)) {
                // a client/server database (e.g. MySQL, PostgreSQL, MS
                // SQLServer)
                String normalizedPath;
                if (path != null && path.length() > 0 && path.charAt(0) != '/') {
                    normalizedPath = '/' + path;
                } else {
                    normalizedPath = path;
                }
                uri = new URI(this.jdbcScheme,
                        (userInfo.length() > 0 ? userInfo.toString() : null),
                        host, port, normalizedPath, query, fragment);
            } else {
                // an embedded / file-based database (e.g. SQLite3, Derby
                // (embedded mode), HSQLDB - use opaque uri
                uri = new URI(this.jdbcScheme, path, fragment);
            }
        } else {
            // If connection_uri comes in as a string, we just pass it
            // through
            uri = new URI(connection_uri.asJavaString());
        }
        return uri;
    }

    /**
     *
     * @param scheme
     */
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
        StringBuilder querySb = new StringBuilder();
        for (Map.Entry<Object, Object> pairs: map.entrySet()){
            String key = (pairs.getKey() != null) ? pairs.getKey().toString()
                    : "";
            String value = (pairs.getValue() != null) ? pairs.getValue()
                    .toString() : "";
            querySb.append(java.net.URLEncoder.encode(key, "UTF-8"))
                    .append("=");
            querySb.append(java.net.URLEncoder.encode(value, "UTF-8"));
            querySb.append("&");
        }
        querySb.deleteCharAt(querySb.length()-1);
        return querySb.toString();
    }

    /**
     *
     * @return
     */
    public RubyObjectAdapter getObjectAdapter() {
        return API;
    }

    /**
     *
     * @param type
     * @param precision
     * @param scale
     * @return
     */
    public RubyType jdbcTypeToRubyType(int type, int precision, int scale) {
        return RubyType.jdbcTypeToRubyType(type, scale);
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
    public IRubyObject getTypecastResultSetValue(Ruby runtime,
            ResultSet rs, int col, RubyType type) throws SQLException,
            IOException {
        //System.out.println(rs.getMetaData().getColumnTypeName(col) + " = " + type.toString());
        switch (type) {
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
                return RubyFixnum.newFixnum(runtime, lng);
            } catch (SQLException sqle) {
                // if getLong failed then use getBigDecimal
                BigDecimal bdi = rs.getBigDecimal(col);
                if (bdi == null) {
                    return runtime.getNil();
                }
                // will return either Fixnum or Bignum
                return RubyBignum.bignorm(runtime, bdi.toBigInteger());
            }
        case FLOAT:
            // Ok, the JDBC api is tricky here. getDouble() will
            // return 0 when the db value is NULL, that's why we use
            // BigDecimal and go back to a double from there
            BigDecimal bdf = rs.getBigDecimal(col);
            if (bdf == null) {
                return runtime.getNil();
            }
            return new RubyFloat(runtime, bdf.doubleValue());
        case BIG_DECIMAL:
            BigDecimal bd = rs.getBigDecimal(col);
            if (bd  == null) {
                return runtime.getNil();
            }
            return runtime.getKernel().callMethod("BigDecimal",
                    runtime.newString(bd.toPlainString()));
        case DATE:
            java.sql.Date date = rs.getDate(col);
            if (date == null) {
                return runtime.getNil();
            }
            return prepareRubyDateFromSqlDate(runtime, date);
        case DATE_TIME:
            java.sql.Timestamp dt = null;
            // DateTimes with all-zero components throw a SQLException with
            // SQLState S1009 in MySQL Connector/J 3.1+
            // See
            // http://dev.mysql.com/doc/refman/5.0/en/connector-j-installing-upgrading.html
            try {
                dt = rs.getTimestamp(col);
            } catch (SQLException ignored) {
            }
            if (dt == null) {
                return runtime.getNil();
            }
            return prepareRubyDateTimeFromSqlTimestamp(runtime, sqlTimestampToDateTime(dt));
        case TIME:
            switch (rs.getMetaData().getColumnType(col)) {
            case Types.TIME:
                java.sql.Time tm = rs.getTime(col);
                if (tm == null) {
                    return runtime.getNil();
                }
                return prepareRubyTimeFromSqlTime(runtime, new DateTime(tm));
            case Types.TIMESTAMP:
                java.sql.Timestamp ts = rs.getTimestamp(col);
                if (ts == null) {
                    return runtime.getNil();
                }
                RubyTime rbt = prepareRubyTimeFromSqlTime(runtime, sqlTimestampToDateTime(ts));
                long usec = (long) (ts.getNanos() / 1000) % 1000;
                rbt.setUSec(usec);
                return rbt;
            case Types.DATE:
                java.sql.Date da = rs.getDate(col);
                if (da == null) {
                    return runtime.getNil();
                }
                return prepareRubyTimeFromSqlDate(runtime, da);
            default:
                String str = rs.getString(col);
                if (str == null) {
                    return runtime.getNil();
                }
                RubyString return_str = newUnicodeString(runtime, str);
                return_str.setTaint(true);
                return return_str;
            }
        case TRUE_CLASS:
            // getBoolean delivers False in case the underlying data is null
            if (rs.getString(col) == null){
                return runtime.getNil();
            }
            return runtime.newBoolean(rs.getBoolean(col));
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
            return API.callMethod(runtime.fastGetModule("Extlib").fastGetClass(
                    "ByteArray"), "new", runtime.newString(bytes));
        case CLASS:
            String classNameStr = rs.getString(col);
            if (classNameStr == null) {
                return runtime.getNil();
            }
            RubyString class_name_str = newUnicodeString(runtime, rs.getString(col));
            class_name_str.setTaint(true);
            return API.callMethod(runtime.fastGetModule("DataObjects"), "full_const_get",
                    class_name_str);
        case NIL:
            return runtime.getNil();
        case STRING:
        default:
            String str = rs.getString(col);
            if (str == null) {
                return runtime.getNil();
            }

            RubyString return_str = newUnicodeString(runtime, str);
            return_str.setTaint(true);
            return return_str;
        }
    }

    protected RubyString newUnicodeString(Ruby runtime, String str) {
        RubyString return_str;
        if (runtime.is1_9()){
            IRubyObject obj = RubyEncoding.getDefaultInternal(RubyString.newEmptyString(runtime));
            Encoding enc = obj.isNil() ? Encoding.load("UTF8") : ((RubyEncoding) obj).getEncoding();
            ByteList value = new ByteList(RubyEncoding.encodeUTF8(str), false);
            return_str = RubyString.newString(runtime, value);
            value.setEncoding(enc);
        }
        else {
            return_str = RubyString.newUnicodeString(runtime, str);
        }
        return return_str;
    }

    /**
     *
     * @param ps
     * @param arg
     * @param idx
     * @throws SQLException
     */
    public void setPreparedStatementParam(PreparedStatement ps,
            IRubyObject arg, int idx) throws SQLException {
        switch (RubyType.inferRubyType(arg)) {
        case FIXNUM:
            ps.setLong(idx, ((RubyInteger) arg).getLongValue());
            break;
        case BIGNUM:
            BigInteger big = ((RubyBignum) arg).getValue();
            if (big.compareTo(LONG_MIN) < 0 || big.compareTo(LONG_MAX) > 0) {
                // set as big decimal
                ps.setBigDecimal(idx, new BigDecimal(((RubyBignum) arg).getValue()));
            } else {
                // set as long
                ps.setLong(idx, ((RubyBignum) arg).getLongValue());
            }
            break;
        case FLOAT:
            ps.setDouble(idx, RubyNumeric.num2dbl(arg));
            break;
        case BIG_DECIMAL:
            ps.setBigDecimal(idx, ((BigDecimal) arg.toJava(Object.class)));
            break;
        case NIL:
            ps.setNull(idx, ps.getParameterMetaData().getParameterType(idx));
            break;
        case TRUE_CLASS:
        case FALSE_CLASS:
            ps.setBoolean(idx, arg.toString().equals("true"));
            break;
        case STRING:
            ps.setString(idx, arg.asString().getUnicodeValue());
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
            DateTime dateTime = ((RubyTime) arg).getDateTime();
            Timestamp ts = new Timestamp(dateTime.getMillis());
            ts.setNanos(ts.getNanos() + (int)(((RubyTime)arg).getUSec()) * 1000);
            ps.setTimestamp(idx, ts, dateTime.toGregorianCalendar());
            break;
        case DATE_TIME:
            DateTime datetime = TIMESTAMP_FORMAT.parseDateTime(arg.toString().replace('T', ' '));
            ps.setTimestamp(idx, new Timestamp(datetime.getMillis()));
            break;
        case REGEXP:
            ps.setString(idx, ((RubyRegexp) arg).source().toString());
            break;
        case OTHER:
        default:
            int jdbcType = ps.getParameterMetaData().getParameterType(idx);
            ps.setObject(idx, arg.asJavaString(), jdbcType);
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
    public boolean registerPreparedStatementReturnParam(String sqlText, PreparedStatement ps, int idx) throws SQLException {
        return false;
    }

    /**
     *
     * @param ps
     * @return
     * @throws SQLException
     */
    public long getPreparedStatementReturnParam(PreparedStatement ps) throws SQLException {
        return 0;
    }

    /**
     *
     * @param sqlText
     * @param args
     * @return
     */
    public String prepareSqlTextForPs(String sqlText, IRubyObject[] args) {
        return sqlText;
    }

    /**
     *
     * @return
     */
    public abstract boolean supportsJdbcGeneratedKeys();

    /**
     *
     * @return
     */
    public abstract boolean supportsJdbcScrollableResultSets();

    /**
     *
     * @return
     */
    public boolean supportsConnectionEncodings() {
        return false;
    }

    /**
     *
     * @return
     */
    public boolean supportsConnectionPrepareStatementMethodWithGKFlag() {
        return true;
    }

    /**
     *
     * @param connection
     * @return
     */
    public ResultSet getGeneratedKeys(Connection connection) {
        return null;
    }

    /**
     *
     * @param connection
     * @param ps
     * @param sqlText
     * @return
     */
    public ResultSet getGeneratedKeys(Connection connection, PreparedStatement ps, String sqlText) throws SQLException{
        return null;
    }

    /**
     *
     * @return
     */
    public Properties getDefaultConnectionProperties() {
        return new Properties();
    }

    /**
     *
     * @param connectionUri
     * @return
     */
    public String getJdbcUri(URI connectionUri) {
      String jdbcUri = connectionUri.toString();
      if (jdbcUri.contains("@")) {
          jdbcUri = connectionUri.toString().replaceFirst("://.*@", "://");
      }

      // Replace . with : in scheme name - necessary for Oracle scheme oracle:thin
      // : cannot be used in JDBC_URI_SCHEME as then it is identified as opaque URI
      // jdbcUri = jdbcUri.replaceFirst("^([a-z]+)(\\.)", "$1:");

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
    public void afterConnectionCallback(IRubyObject doConn, Connection conn,
            Map<String, String> query) throws SQLException {
        // do nothing
    }

    /**
     *
     * @param props
     * @param encodingName
     */
    public void setEncodingProperty(Properties props, String encodingName) {
        // do nothing
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
    public Connection getConnectionWithEncoding(Ruby runtime, IRubyObject connection,
            String url, Properties props) throws SQLException {
        throw new UnsupportedOperationException("This method only returns a method"
                + " for drivers that support specifiying an encoding.");
    }

    /**
     *
     * @param str
     * @return
     */
    public String quoteString(String str) {
        StringBuilder quotedValue = new StringBuilder(str.length() + 2);
        quotedValue.append("\'");
        quotedValue.append(str.replaceAll("'", "''"));
        quotedValue.append("\'");
        return quotedValue.toString();
    }

    /**
     *
     * @param connection
     * @param value
     * @return
     */
    public String quoteByteArray(IRubyObject connection, IRubyObject value) {
        return quoteString(value.asJavaString());
    }

    /**
     *
     * @param s
     * @return
     */
    public String statementToString(Statement s) {
        return s.toString();
    }

    /**
     *
     * @param ts
     * @return
     */
    protected static DateTime sqlTimestampToDateTime(Timestamp ts) {
        if (ts == null)
            return null;
        else
            return new DateTime(ts);
    }

    /**
     *
     * @param runtime
     * @param stamp
     * @return
     */
    protected static IRubyObject prepareRubyDateTimeFromSqlTimestamp(
            Ruby runtime, DateTime stamp) {

        if (stamp.getMillis() == 0) {
            return runtime.getNil();
        }

        int zoneOffset = stamp.getZone().getOffset(stamp.getMillis()) / 1000;

        RubyClass klazz = runtime.fastGetClass("DateTime");

        IRubyObject rbOffset = runtime.getKernel().callMethod("Rational",
                runtime.newFixnum(zoneOffset), runtime.newFixnum(86400));

        return klazz.callMethod(runtime.getCurrentContext(), "civil",
                new IRubyObject[] { runtime.newFixnum(stamp.getYear()),
                        runtime.newFixnum(stamp.getMonthOfYear()),
                        runtime.newFixnum(stamp.getDayOfMonth()),
                        runtime.newFixnum(stamp.getHourOfDay()),
                        runtime.newFixnum(stamp.getMinuteOfHour()),
                        runtime.newFixnum(stamp.getSecondOfMinute()),
                        rbOffset });
    }

    /**
     *
     * @param runtime
     * @param time
     * @return
     */
    protected static RubyTime prepareRubyTimeFromSqlTime(Ruby runtime,
            DateTime time) {
        RubyTime rbTime = RubyTime.newTime(runtime, time);
        return rbTime;
    }

    /**
     *
     * @param runtime
     * @param date
     * @return
     */
    protected static RubyTime prepareRubyTimeFromSqlDate(Ruby runtime,
            Date date) {
        RubyTime rbTime = RubyTime.newTime(runtime, date.getTime());
        return rbTime;
    }

    /**
     *
     * @param runtime
     * @param date
     * @return
     */
    public static IRubyObject prepareRubyDateFromSqlDate(Ruby runtime, java.util.Date date) {
        Calendar c = Calendar.getInstance();
        c.setTime(date);
        RubyClass klazz = runtime.fastGetClass("Date");
        return klazz.callMethod(runtime.getCurrentContext(), "civil",
                new IRubyObject[] { runtime.newFixnum(c.get(Calendar.YEAR)),
                        runtime.newFixnum(c.get(Calendar.MONTH) + 1),
                        runtime.newFixnum(c.get(Calendar.DAY_OF_MONTH)) });
    }

    /**
     *
     * @param obj
     * @return
     */
    private static String stringOrNull(IRubyObject obj) {
        return (!obj.isNil()) ? obj.asJavaString() : null;
    }

    /**
     *
     * @param obj
     * @return
     */
    private static int intOrMinusOne(IRubyObject obj) {
        return (!obj.isNil()) ? RubyFixnum.fix2int(obj) : -1;
    }

    // private static Integer integerOrNull(IRubyObject obj) {
    // return (!obj.isNil()) ? RubyFixnum.fix2int(obj) : null;
    // }
}
