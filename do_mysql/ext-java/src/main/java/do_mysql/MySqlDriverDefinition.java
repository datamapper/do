package do_mysql;

import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Types;
import java.util.Properties;

import org.jruby.runtime.builtin.IRubyObject;

import data_objects.RubyType;
import data_objects.drivers.AbstractDriverDefinition;

public class MySqlDriverDefinition extends AbstractDriverDefinition {

    public final static String URI_SCHEME = "mysql";
    public final static String RUBY_MODULE_NAME = "Mysql";

    public MySqlDriverDefinition() {
        super(URI_SCHEME, RUBY_MODULE_NAME);
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
    public boolean supportsCalendarsInJDBCPreparedStatement() {
        return false;
    }

    @Override
    public Properties getDefaultConnectionProperties() {
        Properties props = new Properties();
        props.put("useUnicode", "yes");
        return props;
    }

    @Override
    public void setEncodingProperty(Properties props, String encodingName) {
        if ("latin1".equals(encodingName)) {
            // example of mapping encoding name to Java-Style character
            // encoding name (see http://dev.mysql.com/doc/refman/5.1/en/connector-j-reference-charsets.html)
            encodingName = "ISO8859_1";
        }
        props.put("characterEncoding", encodingName);
    }

    @Override
    public String sanitizePreparedStatementText(String psText) {
        // XXX the quotings coming from the dm-core/adapters needs to be
        // rectified BUT might also break custom sql
        return psText.replace("\"", "`");
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
    public String toString(PreparedStatement ps) {
        return ps.toString().replaceFirst(".*].-\\s*", "");
    }

}
