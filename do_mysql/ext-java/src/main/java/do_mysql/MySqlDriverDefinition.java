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

    public MySqlDriverDefinition() {
        super(URI_SCHEME, RUBY_MODULE_NAME);
    }

    @Override
    protected IRubyObject doGetTypecastResultSetValue(Ruby runtime,
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
    public boolean supportsJdbcGeneratedKeys()
    {
        return true;
    }

    @Override
    public boolean supportsJdbcScrollableResultSets()
    {
        return true;
    }

    @Override
    public boolean supportsConnectionEncodings()
    {
        return true;
    }

    @Override
    public Properties getDefaultConnectionProperties() {
        Properties props = new Properties();
        props.put("useUnicode", "yes");
        props.put("sessionVariables", "sql_auto_is_null=0,sql_mode='ANSI,NO_AUTO_VALUE_ON_ZERO,NO_DIR_IN_CREATE,NO_ENGINE_SUBSTITUTION,NO_UNSIGNED_SUBTRACTION,TRADITIONAL'");
        return props;
    }

    @Override
    public void setEncodingProperty(Properties props, String encodingName) {
        props.put("characterEncoding", encodingName);
    }

    @Override
    public java.sql.Connection getConnectionWithEncoding(Ruby runtime,
            IRubyObject connection, String url, Properties props) throws SQLException {
        java.sql.Connection conn;
        try {
            conn = DriverManager.getConnection(url, props);
        } catch (SQLException eex) {
            Pattern p = Pattern.compile("Unsupported character encoding '(.+)'.");
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

    @Override
    public String quoteString(String str) {
        StringBuffer quotedValue = new StringBuffer(str.length() + 2);
        quotedValue.append("\'");
        quotedValue.append(str.replaceAll("'", "\\\\'"));
        // TODO: handle backslashes
        quotedValue.append("\'");
        return quotedValue.toString();
    }

    @Override
    public String statementToString(Statement s) {
        return s.toString().replaceFirst(".*].-\\s*", "");
    }

}
