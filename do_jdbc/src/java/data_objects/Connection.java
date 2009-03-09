package data_objects;

import data_objects.drivers.DriverDefinition;
import java.io.UnsupportedEncodingException;
import java.net.URISyntaxException;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.StringTokenizer;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyObjectAdapter;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.Java;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.javasupport.JavaObject;
import org.jruby.runtime.Block;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;

/**
 * Connection Class
 *
 * @author alexbcoles
 */
@JRubyClass(name = "Connection")
public class Connection extends RubyObject {

    public final static String RUBY_CLASS_NAME = "Connection";
    private static RubyObjectAdapter api;
    private static DriverDefinition driver;
    private static String moduleName;
    private static String errorName;
    private final static ObjectAllocator CONNECTION_ALLOCATOR = new ObjectAllocator() {

        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Connection instance = new Connection(runtime, klass);
            return instance;
        }
    };

    public static RubyClass createConnectionClass(final Ruby runtime,
            final String moduleName, final String errorName,
            final DriverDefinition driverDefinition) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyModule driverModule = (RubyModule) doModule.getConstant(moduleName);
        RubyClass connectionClass =
                driverModule.defineClassUnder(RUBY_CLASS_NAME,
                superClass, CONNECTION_ALLOCATOR);
        Connection.api = JavaEmbedUtils.newObjectAdapter();
        Connection.driver = driverDefinition;
        Connection.moduleName = moduleName;
        Connection.errorName = errorName;
        connectionClass.defineAnnotatedMethods(Connection.class);
        return connectionClass;
    }

    private Connection(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }

    // -------------------------------------------------- DATAOBJECTS PUBLIC API
    @JRubyMethod(required = 1)
    public static IRubyObject initialize(IRubyObject recv, IRubyObject uri) {
        // System.out.println("============== initialize called " + uri);
        Ruby runtime = recv.getRuntime();
        String jdbcDriver = null;
        java.net.URI connectionUri;

        try {
            connectionUri = parseConnectionUri(uri);
        } catch (URISyntaxException ex) {
            throw runtime.newArgumentError("Malformed URI: " + ex);
            //Logger.getLogger(Connection.class.getName()).log(Level.SEVERE, null, ex);
        } catch (UnsupportedEncodingException ex) {
            throw runtime.newArgumentError("Unsupported Encoding in Query Parameters" + ex);
        }

        if (connectionUri.getQuery() != null) {
            Map<String, String> query;
            try {
                query = DataObjectsUtils.parseQueryString(connectionUri.getQuery());
            } catch (UnsupportedEncodingException ex) {
                throw runtime.newArgumentError("Unsupported Encoding in Query Parameters" + ex);
                //Logger.getLogger(Connection.class.getName()).log(Level.SEVERE, null, ex);
            }

            jdbcDriver = query.get("driver");
            //String protocol = query.get("protocol"); XXX : not sure of the point of this
        }

        // Load JDBC Driver Class
        if (jdbcDriver != null) {
            try {
                Class.forName(jdbcDriver).newInstance();
            } catch (ClassNotFoundException cfe) {
                throw runtime.newArgumentError("Driver class library (" + jdbcDriver + ") not found.");
                //Logger.getLogger(Connection.class.getName()).log(Level.SEVERE, null, cfe);
            } catch (InstantiationException ine) {
                throw runtime.newArgumentError("Driver class library you specified could not be instantiated");
            } catch (IllegalAccessException iae) {
                throw runtime.newArgumentError("Driver class library is not available:" + iae.getLocalizedMessage());
            }
            // should be handled implicitly
            // DriverManager.registerDriver(driver);
        }

        java.sql.Connection conn;

        try {
            final String JNDI_PROTO = "jndi://";
            if (connectionUri.getPath() != null && connectionUri.getPath().startsWith(JNDI_PROTO)) {
                String jndiName = connectionUri.getPath().substring(JNDI_PROTO.length());
                try {
                    InitialContext context = new InitialContext();
                    DataSource dataSource = (DataSource) context.lookup(jndiName);
                    // TODO maybe allow username and password here as well !??!
                    conn = dataSource.getConnection();
                } catch (NamingException ex) {
                    throw runtime.newRuntimeError("Can't lookup datasource: " + connectionUri.toString() + "\n\t" + ex.getLocalizedMessage());
                }
            } else if (connectionUri.toString().contains("@")) {
                // uri.getUserInfo() gave always null, so do it manually
                // TODO: See if we can replace with connectionUri.getUserInfo()
                String userInfo =
                        connectionUri.toString().replaceFirst(".*://", "").replaceFirst("@.*", "");
                String jdbcUri = connectionUri.toString().replaceFirst(userInfo + "@", "");
                if (!userInfo.contains(":")) {
                    userInfo += ":";
                }
                if (!jdbcUri.startsWith("jdbc:")) {
                    jdbcUri = "jdbc:" + jdbcUri;
                }

                conn = DriverManager.getConnection(jdbcUri,
                        userInfo.substring(0, userInfo.indexOf(":")),
                        userInfo.substring(userInfo.indexOf(":") + 1));
            } else {
                String jdbcUri = connectionUri.toString();
                if (!jdbcUri.startsWith("jdbc:")) {
                    jdbcUri = "jdbc:" + jdbcUri;
                }
                conn = DriverManager.getConnection(jdbcUri);
            }

        } catch (SQLException ex) {
            //Logger.getLogger(Connection.class.getName()).log(Level.SEVERE, null, ex);
            throw DataObjectsUtils.newDriverError(runtime, errorName, "Can't connect: " + connectionUri.toString() + "\n\t" + ex.getLocalizedMessage());
        }

        IRubyObject rubyconn1 = wrappedConnection(recv, conn);
        //IRubyObject rubyconn1 = JavaEmbedUtils.javaToRuby(runtime, conn);

        api.setInstanceVariable(recv, "@uri", uri);
        api.setInstanceVariable(recv, "@connection", rubyconn1);
        rubyconn1.dataWrapStruct(conn);

        return runtime.getTrue();
    }

    @JRubyMethod
    public static IRubyObject dispose(IRubyObject recv) {
        // System.out.println("============== dispose called");
        Ruby runtime = recv.getRuntime();

        java.sql.Connection prev = getConnection(recv);
        if (prev == null) {
            return runtime.getFalse();
        }

        try {
            prev.close();
        } catch (Exception e) {
            return runtime.getFalse();
        }

        return runtime.getTrue();
    }

    // -------------------------------------------------- PRIVATE HELPER METHODS
    private static IRubyObject wrappedConnection(IRubyObject recv, java.sql.Connection c) {
        return Java.java_to_ruby(recv, JavaObject.wrap(recv.getRuntime(), c), Block.NULL_BLOCK);
    }

    private static java.sql.Connection getConnection(IRubyObject recv) {
        java.sql.Connection conn = (java.sql.Connection) recv.dataGetStruct();
        return conn;
    }

    /**
     * Convert a DataObjects URI to a java.net.URI
     *
     * @param uri
     * @return
     */
    private static java.net.URI parseConnectionUri(IRubyObject connection_uri)
            throws URISyntaxException, UnsupportedEncodingException {
        java.net.URI uri;

        if ("DataObjects::URI".equals(connection_uri.getType().getName())) {
            String query = null;
            StringBuffer userInfo = new StringBuffer();

            String scheme = DataObjectsUtils.stringOrNull(api.callMethod(connection_uri, "scheme"));
            String user = DataObjectsUtils.stringOrNull(api.callMethod(connection_uri, "user"));
            String password = DataObjectsUtils.stringOrNull(api.callMethod(connection_uri, "password"));
            String host = DataObjectsUtils.stringOrNull(api.callMethod(connection_uri, "host"));
            int port = DataObjectsUtils.intOrMinusOne(api.callMethod(connection_uri, "port"));
            String path = DataObjectsUtils.stringOrNull(api.callMethod(connection_uri, "path"));
            IRubyObject query_values = api.callMethod(connection_uri, "query");
            String fragment = DataObjectsUtils.stringOrNull(api.callMethod(connection_uri, "fragment"));

            if (user != null && !"".equals(user)) {
                userInfo.append(user);
                if (password != null && !"".equals(password)) {
                    userInfo.append(":").append(password);
                }
            }

            if (query_values.isNil()) {
                query = null;
            } else if (query_values instanceof RubyHash) {
                query = DataObjectsUtils.mapToQueryString(query_values.convertToHash());
            } else {
                query = api.callMethod(query_values, "to_s").asJavaString();
            }

            if (scheme != null) {
                // Exceptions: PostgreSQL and SQLite3 uris require their own handling,
                // and need to be of the form 'jdbc:postgresql' (NOT 'jdbc:postgres')
                // and 'jdbc:sqlite' NOT 'jdbc:sqlite3' respectively.
                if ("postgres".equals(scheme)) scheme = "postgresql";
                if ("sqlite3".equals(scheme)) scheme = "sqlite";
            }

            if (host != null && !"".equals(host)) {
                // a client/server database (e.g. MySQL, PostgreSQL, MS SQLServer)
                uri = new java.net.URI(scheme, userInfo.toString(), host, port, path, query, fragment);
            } else {
                // an embedded / file-based database (e.g. SQLite3, Derby (embedded mode), HSQLDB
                uri = new java.net.URI(scheme, "", path, query, fragment);
            }
        } else {
            // If connection_uri comes in as a string, we just pass it through
            uri = new java.net.URI(connection_uri.asJavaString());
        }
        return uri;
    }


}
