package do_postgres;

import data_objects.drivers.AbstractDriverDefinition;
import data_objects.RubyType;

import java.util.Properties;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Types;

import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.RubyString;

public class PostgresDriverDefinition extends AbstractDriverDefinition {

    public final static String URI_SCHEME = "postgres";
    public final static String JDBC_URI_SCHEME = "postgresql";
    public final static String RUBY_MODULE_NAME = "Postgres";

    public PostgresDriverDefinition() {
        super(URI_SCHEME, JDBC_URI_SCHEME, RUBY_MODULE_NAME);
    }

    @Override
    public boolean supportsJdbcGeneratedKeys()
    {
        return false;
    }

    @Override
    public boolean supportsJdbcScrollableResultSets() {
        return true;
    }

    @Override
    public void setPreparedStatementParam(PreparedStatement ps,
            IRubyObject arg, int idx) throws SQLException {
        int jdbcType;
        switch (RubyType.getRubyType(arg.getType().getName())) {
        case STRING:
            jdbcType = ps.getParameterMetaData().getParameterType(idx);
            switch (jdbcType) {
            case Types.INTEGER:
                // conversion for '.execute_reader("2")'
                ps.setInt(idx, Integer.valueOf(arg.toString()));
                break;
            default:
                ps.setString(idx, arg.toString());
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

}
