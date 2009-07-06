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
    public boolean supportsConnectionEncodings()
    {
        return true;
    }

    @Override	
    public void setPreparedStatementParam(PreparedStatement ps,
            IRubyObject arg, int idx) throws SQLException {
        switch (RubyType.getRubyType(arg.getType().getName())) {
        case BYTE_ARRAY:
            final int jdbcType = ps.getParameterMetaData().getParameterType(idx);
            switch(jdbcType){
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

    @Override
    public void setEncodingProperty(Properties props, String encodingName) {
        // this is redundant as of Postgres 8.0, according to the JDBC documentation:
        // http://jdbc.postgresql.org/documentation/80/connect.html
        props.put("charSet", encodingName);
    }

}
