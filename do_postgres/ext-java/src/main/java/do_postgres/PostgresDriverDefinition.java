package do_postgres;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.Map;
import java.util.regex.Pattern;

import org.jruby.RubyBoolean;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;

import data_objects.RubyType;
import data_objects.drivers.AbstractDriverDefinition;
import data_objects.util.JDBCUtil;
import java.util.Properties;

public class PostgresDriverDefinition extends AbstractDriverDefinition {

    public final static String URI_SCHEME = "postgres";
    public final static String JDBC_URI_SCHEME = "postgresql";
    public final static String RUBY_MODULE_NAME = "Postgres";
    public final static String JDBC_DRIVER = "org.postgresql.Driver";

    public PostgresDriverDefinition() {
        super(URI_SCHEME, JDBC_URI_SCHEME, RUBY_MODULE_NAME, JDBC_DRIVER);
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
        return true;
    }

    /**
     *
     * @return
     */
    @Override
    public Properties getDefaultConnectionProperties() {
        Properties props = new Properties();
        // the underlying PostgreSQL JDBC driver, as with libpg, defaults to the
        // same user as "as the operating system name of the user running the
        // application", i.e. System.getProperty("user.name").
        // TODO: Check this is the CORRECT behavior: we override this to use
        // "postgres" user instead as default. As convention, this is the unix
        // account that with  PG root/superuser privileges.
        props.put("user", "postgres");
        return props;
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
        int jdbcType;
        switch (RubyType.inferRubyType(arg)) {
        case STRING:
            jdbcType = ps.getParameterMetaData().getParameterType(idx);
            switch (jdbcType) {
            case Types.INTEGER:
                // conversion for '.execute_reader("2")'
                ps.setInt(idx, Integer.valueOf(arg.toString()));
                break;
            default:
                ps.setString(idx, arg.asString().getUnicodeValue());
            }
            break;
        case BYTE_ARRAY:
            jdbcType = ps.getParameterMetaData().getParameterType(idx);
            switch (jdbcType) {
            case Types.BINARY:
                ps.setBytes(idx, ((RubyString) arg).getBytes());
                break;
            default:
                //XXX Postgres doesn't typecast bytea type to integer,decimal etc
                //so it's done manually by the driver
                ps.setObject(idx,arg.asJavaString(),jdbcType);
            }
            break;
        default:
            super.setPreparedStatementParam(ps, arg, idx);
        }
    }

    /**
     *
     * @param doConn
     * @param conn
     * @param query
     * @throws SQLException
     */
    @Override
    public void afterConnectionCallback(IRubyObject doConn,
            Connection conn, Map<String, String> query) throws SQLException {
        checkStandardConformingStrings(doConn, conn);
        setSearchPath(conn, query);
    }

    private final static Pattern validValue = Pattern.compile("^[a-zA-Z][a-zA-Z0-9-]*(,[a-zA-Z][a-zA-Z0-9-]*)*$");

    /**
     * Escape the given value to be used in a SET command.
     * Right now the method only checks if the given value
     * contains only the following characters: a-zA-Z0-9,-
     *
     * @param value Value to escape
     * @return Escaped value which can be safely used in a
     *         SET command.
     */
    private String escapeValue(String value) throws SQLException {
        if (!validValue.matcher(value).matches())
            throw new SQLException("Invalid query parameter value: " + value);
        return value;
    }

    /**
     * Sets the search_path for the given connection based on
     * the search_path query parameter.
     *
     * @param conn Connection to set search_path for.
     * @param query Map containing all query parameters.
     */
    private void setSearchPath(Connection conn, Map<String, String> query) throws SQLException {
        final String search_path = "search_path";
        if (query == null || !query.containsKey(search_path))
            return;

        PreparedStatement st = null;
        try {
            st = conn.prepareStatement("SET search_path = " + escapeValue(query.get(search_path)));
            st.executeUpdate();
        } catch (SQLException e) {
            // Ignore.
        } finally {
            JDBCUtil.close(st);
        }
    }

    /**
     *
     * @param doConn
     * @param conn
     * @throws SQLException
     */
    private void checkStandardConformingStrings(IRubyObject doConn, Connection conn) throws SQLException {
        Statement st = null;
        boolean standardConformingStrings = false;
        try {
            st = conn.createStatement();
            ResultSet rs = st.executeQuery("SHOW standard_conforming_strings");
            if (rs.next()) {
                standardConformingStrings = rs.getString(1).equals("on");
            }
        } catch (SQLException e) {
            // Ignore. It must be an old server that doesn't support standard_conforming_strings
        } finally {
            JDBCUtil.close(st);
        }

        getObjectAdapter().setInstanceVariable(doConn, "@standard_conforming_strings",
            RubyBoolean.newBoolean(doConn.getRuntime(), standardConformingStrings));
    }

    /**
     *
     * @param doConn
     * @param value
     * @return
     */
    @Override
    public String quoteByteArray(IRubyObject doConn, IRubyObject value) {
        boolean stdStrings = getObjectAdapter().getInstanceVariable(doConn, "@standard_conforming_strings").isTrue();
        byte[] bytes = value.asString().getBytes();

        return escapeBytes(stdStrings, bytes);
    }

    /**
     *
     * @param stdStrings
     * @param bytes
     * @return
     */
    private String escapeBytes(boolean stdStrings, byte[] bytes) {
        char[] output = new char[calcEscapedLength(stdStrings, bytes)];
        int offset = 1;
        output[0] = '\'';
        for (int b : bytes) {
            b &= 0xff;
            if (b < 0x20 || b > 0x7e) {
                if (! stdStrings) {
                    output[offset++] = '\\';
                }
                output[offset++] = '\\';
                output[offset++] = (char)((b >> 6) + '0');
                output[offset++] = (char)(((b >> 3) & 07) + '0');
                output[offset++] = (char)((b & 07) + '0');
            } else if (b == '\'') {
                output[offset++] = '\\';
                output[offset++] = '\\';
            } else if (b == '\\') {
                if (! stdStrings) {
                    output[offset++] = '\\';
                    output[offset++] = '\\';
                }
                output[offset++] = '\\';
                output[offset++] = '\\';
            } else {
                output[offset++] = (char)b;
            }
        }
        output[offset] = '\'';
        return new String(output);
    }

    /**
     *
     * @param stdStrings
     * @param bytes
     * @return
     */
    private int calcEscapedLength(boolean stdStrings, byte[] bytes) {
        int length = 2;
        int backSlashLength = stdStrings ? 1 : 2;
        for (int b : bytes) {
            b &= 0xff;
            if (b < 0x20 || b > 0x7e) {
                length += backSlashLength + 3;
            } else if (b == '\'') {
                length += 2;
            } else if (b == '\\') {
                length += backSlashLength + backSlashLength;
            } else {
                length++;
            }
        }
        return length;
    }

}
