package do_oracle;

import data_objects.drivers.AbstractDriverDefinition;
import java.util.Properties;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.SQLException;

public class OracleDriverDefinition extends AbstractDriverDefinition {

    public final static String URI_SCHEME = "oracle";
    // . will be replaced with : in Connection.java before connection
    public final static String JDBC_URI_SCHEME = "oracle.thin";
    public final static String RUBY_MODULE_NAME = "Oracle";

    public OracleDriverDefinition() {
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
        return false;
    }

    @Override
    public Properties getDefaultConnectionProperties() {
        Properties props = new Properties();
        // Set prefetch rows to 100 to increase fetching performance SELECTs with many rows
        props.put("defaultRowPrefetch", "100");
        return props;
    }

    @Override
    public void afterConnectionCallback(Connection conn)
            throws SQLException {
        exec(conn, "alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS'");
        exec(conn, "alter session set nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS.FF'");
        exec(conn, "alter session set nls_timestamp_tz_format = 'YYYY-MM-DD HH24:MI:SS.FF TZH:TZM'");
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
