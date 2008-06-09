package data_objects;

import data_objects.drivers.DriverDefinition;
import java.io.UnsupportedEncodingException;
import java.net.URISyntaxException;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
import java.util.StringTokenizer;
import org.jruby.Ruby;
import org.jruby.RubyClass;
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
import org.jruby.runtime.ThreadContext;
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
        Ruby runtime = recv.getRuntime();
        String jdbcDriver = null;
        java.net.URI connectionUri;

        try {
            connectionUri = parseConnectionUri(uri);
        } catch (URISyntaxException ex) {
            throw runtime.newArgumentError("Malformed URI: " + ex);
        //Logger.getLogger(Connection.class.getName()).log(Level.SEVERE, null, ex);
        }

        if (connectionUri.getQuery() != null) {
            Map<String, String> query;
            try {
                query = parseQueryString(connectionUri.getQuery());
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
            conn = DriverManager.getConnection(connectionUri.toString());
        } catch (SQLException ex) {
            //Logger.getLogger(Connection.class.getName()).log(Level.SEVERE, null, ex);
            throw runtime.newRuntimeError("Can't connect:" + connectionUri + ex.getLocalizedMessage());
        }

        IRubyObject rubyconn1 = wrappedConnection(recv, conn);
        //IRubyObject rubyconn1 = JavaEmbedUtils.javaToRuby(runtime, conn);

        api.setInstanceVariable(recv, "@uri", uri);
        api.setInstanceVariable(recv, "@connection", rubyconn1);
        rubyconn1.dataWrapStruct(conn);

        return runtime.getTrue();
    }

    @JRubyMethod
    public static IRubyObject real_close(IRubyObject recv) {
        Ruby runtime = recv.getRuntime();

        java.sql.Connection prev = getConnection(recv);
        if (prev != null) {
            try {
                prev.close();
            } catch (Exception e) {
            }
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
     * Convert a DataMapper URI (String, Addressable::URI) to a java.net.URI
     *
     * @param uri
     * @return
     */
    private static java.net.URI parseConnectionUri(IRubyObject connectionUri)
            throws URISyntaxException {
        java.net.URI uri;
        String fullUri = api.callMethod(connectionUri, "to_s").asJavaString();
        uri = new java.net.URI(fullUri);
        return uri;
    }

    /**
     * Convert a query string (e.g. driver=org.postgresql.Driver&protocol=postgresql)
     * to a Map of values.
     *
     * @param query
     * @return
     */
    private static Map<String, String> parseQueryString(String query)
            throws UnsupportedEncodingException {
        if (query == null) {
            return null;
        }
        Map<String, String> nameValuePairs = new HashMap<String, String>();
        StringTokenizer stz = new StringTokenizer(query, "&");

        // Tokenize at and for name / value pairs
        while (stz.hasMoreTokens()) {
            String nameValueToken = stz.nextToken();
            // Split at = to split the pairs
            int i = nameValueToken.indexOf("=");
            String name = nameValueToken.substring(0, i);
            String value = nameValueToken.substring(i + 1);
            // Name and value should be URL decoded
            name = java.net.URLDecoder.decode(name, "UTF-8");
            value = java.net.URLDecoder.decode(value, "UTF-8");
            nameValuePairs.put(name, value);
        }

        return nameValuePairs;
    }
}