package do_openedge;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.sql.Connection;
import java.sql.ResultSetMetaData;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.net.URISyntaxException;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.net.URI;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;

import data_objects.RubyType;
import data_objects.drivers.AbstractDriverDefinition;

public class OpenEdgeDriverDefinition extends AbstractDriverDefinition {

    public final static String URI_SCHEME = "openedge";
    // . in JDBC_URI_SCHEME will be replaced with : in Connection.java before connection
    public final static String JDBC_URI_SCHEME = "datadirect.openedge";
    public final static String RUBY_MODULE_NAME = "Openedge";
    public final static String JDBC_DRIVER = "com.ddtek.jdbc.openedge.OpenEdgeDriver";

    /**
     *
     */
    public OpenEdgeDriverDefinition() {
        super(URI_SCHEME, JDBC_URI_SCHEME, RUBY_MODULE_NAME, JDBC_DRIVER);
    }

    /**
     *
     * Verified by checking that
     * conn.getMetaData().supportsGetGeneratedKeys() == false
     * and confirmed experimentally - when calling conn.prepareStatement with
     * Statement.RETURN_GENERATED_KEYS, an error is thrown:
     * java.sql.SQLFeatureNotSupportedException
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
     * Verified by successfully calling conn.prepareStatement with
     * Statement.NO_GENERATED_KEYS
     *
     * @return
     */
    public boolean supportsConnectionPrepareStatementMethodWithGKFlag() {
        return true;
    }

    /**
     *
     * Needs to parse raw SQL text due to the driver returning null for
     * ps.getMetaData() on INSERT statements (SELECT queries seem to work).
     *
     * @param connection
     * @param ps
     * @param sqlText
     * @return
     */
    @Override
    public ResultSet getGeneratedKeys(Connection connection, PreparedStatement ps, String sqlText) throws SQLException {
        Pattern p = Pattern.compile("^\\s*INSERT.+INTO\\s+([^(]+)[\\s(]*", Pattern.CASE_INSENSITIVE);
        Matcher m = p.matcher(sqlText);
        if (m.find()) {
            if (m.groupCount() > 0) {
                String tableName = m.group(1).trim();
                // Using plain Statement as table names can't be bound like '?' parameters in PreparedStatements :(
                Statement s = connection.createStatement();
                ResultSet result = s.executeQuery("SELECT TOP 1 " + tableName + "_id_seq.CURRVAL FROM SYSPROGRESS.SYSCALCTABLE");
                return result;
            }
        }
        return null;
    }


    /**
     *
     * Verified by creating a statement with ResultSet.TYPE_SCROLL_INSENSITIVE
     * and successfully scrolling forward (rs.next()) *and backward* (rs.previous())!
     *
     * @return
     */
    @Override
    public boolean supportsJdbcScrollableResultSets() {
        return true;
    }

    /**
     *
     *
     * @return
     */
    @Override
    public Properties getDefaultConnectionProperties() {
        Properties props = new Properties();
        // PUB is the schema that can be seen by the OpenEdge Data Dictionary
        props.put("defaultSchema", "pub");
        return props;
    }

    /**
     *
     * This is needed to translate OpenEdge's funky JDBC URI
     *
     * @param connection_uri
     * @return
     * @throws URISyntaxException
     * @throws UnsupportedEncodingException
     */
    @SuppressWarnings("unchecked")
    public URI parseConnectionURI(IRubyObject connection_uri)
            throws URISyntaxException, UnsupportedEncodingException {
        if ("DataObjects::URI".equals(connection_uri.getType().getName())) {
            // DataObjects::URI get parsed by default adapter just fine
            return super.parseConnectionURI(connection_uri);
        } else {
            // Handle JDBC strings here
            String connUriStr = connection_uri.asJavaString();
            String postScheme = connUriStr.split("://")[1];
            URI connectionUri = new URI(JDBC_URI_SCHEME + "://" + postScheme);

            // Filter the query string
            String user = "";
            String password = "";
            String query = null;
            if (connectionUri.getQuery() != null) {
                String[] parts = connectionUri.getQuery().split("&");
                for (int i=0; i < parts.length; i++) {
                    if (parts[i].toLowerCase().startsWith("user")) {
                        String userParts[] = parts[i].split("=");
                        if ((userParts.length) > 1)
                            user = userParts[1];
                    } else if (parts[i].toLowerCase().startsWith("password")) {
                        String passParts[] = parts[i].split("=");
                        if ((passParts.length) > 1)
                            password = passParts[1];
                    } else {
                        if (query == null)
                            query = "?" + parts[i];
                        else
                            query += "&" + parts[i];
                    }
                }
            }
            String userInfo = null;
            if (user != "") {
                userInfo = user + ":" + password;
            }
            return new URI(connectionUri.getScheme(),
                           userInfo,
                           connectionUri.getHost(),
                           connectionUri.getPort(),
                           connectionUri.getPath(),
                           connectionUri.getQuery(),
                           connectionUri.getFragment());
        }
    }

    /**
     *
     * This is needed to translate from the normal JDBC-style URI into the
     * proprietary mess that OpenEdge requires
     *
     * @param connectionUri
     * @return
     */
    @Override
    public String getJdbcUri(URI connectionUri) {
        // Create the string 'jdbc:datadirect:openedge'
        String jdbcPrefix = "jdbc:" + JDBC_URI_SCHEME.replaceAll("\\.", ":");

        String jdbcUri = jdbcPrefix + "://" + connectionUri.getHost() + ":" + connectionUri.getPort();

        String dbName = connectionUri.getPath();
        if (dbName != null) {
            dbName = dbName.replaceFirst("^\\/", "");
            jdbcUri += ";databasename=" + dbName;
        }

        // Iterate through each piece of the query string...
        if (connectionUri.getQuery() != null) {
            String[] parts = connectionUri.getQuery().split("&");
            for (int i=0; i < parts.length; i++) {
                if (!parts[i].toLowerCase().startsWith("user") && !parts[i].toLowerCase().startsWith("password")) {
                    jdbcUri += ";" + parts[i];
                }
            }
        }

        return jdbcUri;
    }
}
