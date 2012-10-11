package data_objects;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;
import static data_objects.util.StringUtil.appendQuoted;

import java.io.UnsupportedEncodingException;
import java.net.URISyntaxException;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.StringTokenizer;

import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Arity;
import org.jruby.runtime.Block;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.callback.Callback;

import data_objects.drivers.DriverDefinition;
import data_objects.errors.Errors;
import data_objects.util.JDBCUtil;

/**
 * Connection Class.
 *
 * @author alexbcoles
 */
@SuppressWarnings("serial")
@JRubyClass(name = "Connection")
public final class Connection extends DORubyObject {

    public static final String RUBY_CLASS_NAME = "Connection";

    private static final String UTF8_ENCODING = "UTF-8";

    private java.sql.Connection sqlConnection;
    private java.net.URI connectionUri;
    private Map<String, String> query;
    private String encoding;

    private static final ObjectAllocator CONNECTION_ALLOCATOR = new ObjectAllocator() {

        public IRubyObject allocate(final Ruby runtime, final RubyClass klass) {
            return new Connection(runtime, klass);
        }
    };

    /**
     *
     * @param runtime
     * @param driver
     * @return
     */
    public static RubyClass createConnectionClass(final Ruby runtime,
            final DriverDefinition driver) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyModule driverModule = (RubyModule) doModule.getConstant(driver
                .getModuleName());
        RubyClass connectionClass = driverModule.defineClassUnder(
                RUBY_CLASS_NAME, superClass, CONNECTION_ALLOCATOR);
        connectionClass.defineAnnotatedMethods(Connection.class);
        setDriverDefinition(connectionClass, runtime, driver);

        if (driver.supportsConnectionEncodings()) {
            connectionClass.defineFastMethod("character_set", new Callback() {
                public Arity getArity() {
                    return Arity.NO_ARGUMENTS;
                }
                public IRubyObject execute(final IRubyObject recv, final IRubyObject[] args, Block block) {
                    return recv.getInstanceVariables().fastGetInstanceVariable("@encoding");
                }
            });
        }
        return connectionClass;
    }

    /**
     *
     * @param runtime
     * @param klass
     */
    private Connection(final Ruby runtime, final RubyClass klass) {
        super(runtime, klass);
    }

    // -------------------------------------------------- DATAOBJECTS PUBLIC API

    /**
     *
     * @param uri
     * @return
     */
    @JRubyMethod(required = 1)
    public IRubyObject initialize(final IRubyObject uri) {
        // System.out.println("============== initialize called " + uri);
        Ruby runtime = getRuntime();

        try {
            connectionUri = driver.parseConnectionURI(uri);
        } catch (URISyntaxException ex) {
            //XXX Nothing to close
            throw runtime.newArgumentError("Malformed URI: " + ex);
        } catch (UnsupportedEncodingException ex) {
            //XXX Nothing to close
            throw runtime.newArgumentError("Unsupported Encoding in Query Parameters" + ex);
        }

        if (connectionUri.getQuery() != null) {
            try {
                query = parseQueryString(connectionUri.getQuery());
            } catch (UnsupportedEncodingException ex) {
                //XXX Nothing to close
                throw runtime.newArgumentError("Unsupported Encoding in Query Parameters" + ex);
            }

            if (driver.supportsConnectionEncodings()) {
                encoding = query.get("encoding");
                if (encoding == null) {
                    encoding = query.get("charset");
                }
            }
        }

        if (driver.supportsConnectionEncodings()) {
            // default encoding to UTF-8, if not specified
            if (encoding == null) {
                encoding = UTF8_ENCODING;
            }
            api.setInstanceVariable(this, "@encoding", runtime.newString(encoding));
        }

        // #to_s implemented in Ruby relies on this @uri ivar
        api.setInstanceVariable(this, "@uri", uri);

        connect();
        return runtime.getTrue();
    }

    public void connect() {
        Ruby runtime = getRuntime();

        java.sql.Connection conn = null;

        try {
            if (connectionUri.getSchemeSpecificPart() != null && connectionUri.getScheme().equals("java")) {
                String jndiName = connectionUri.toString();

                try {
                    InitialContext context = new InitialContext();
                    DataSource dataSource = (DataSource) context.lookup(jndiName);
                    conn = dataSource.getConnection();
                } catch (NamingException ex) {
                    JDBCUtil.close(conn);
                    throw Errors.newConnectionError(runtime, "Can't lookup datasource: "
                                                  + connectionUri.toString() + "\n\t" + ex.getLocalizedMessage());
                }
            } else {
                Properties props = driver.getDefaultConnectionProperties();

                String jdbcUri = driver.getJdbcUri(connectionUri);

                String userInfo = connectionUri.getUserInfo();
                if (userInfo != null) {
                  if (!userInfo.contains(":")) {
                      userInfo += ":";
                  }
                  String username = userInfo.substring(0, userInfo.indexOf(":"));
                  String password = userInfo.substring(userInfo.indexOf(":") + 1);
                  props.put("user", username);
                  props.put("password", password);
                }

                if (driver.supportsConnectionEncodings()) {
                    // we set encoding properties, and retry on failure
                    driver.setEncodingProperty(props, encoding);
                    conn = driver.getConnectionWithEncoding(runtime, this, jdbcUri, props);
                } else {
                    // if the driver does not use encoding, connect normally
                    conn = driver.getConnection(jdbcUri, props);
                }
            }

        } catch (SQLException ex) {
            JDBCUtil.close(conn);
            throw Errors.newSqlError(runtime, driver, "Can't connect: "
                                        + connectionUri.toString() + "\n\t" + ex.getLocalizedMessage());
        }

        // some jdbc driver just return null if the subscheme of URI does not match
        if(conn == null){
            //XXX Nothing to close
            throw Errors.newSqlError(runtime, driver, "Can't connect: "
                                        + connectionUri.toString());
        }

        // Callback for setting connection properties after connection is established
        try {
            driver.afterConnectionCallback(this, conn, query);
        } catch (SQLException ex) {
            JDBCUtil.close(conn);
            throw Errors.newSqlError(runtime, driver, "Connection initialization error:"
                                     + "\n\t" + ex.getLocalizedMessage());
        }

        this.sqlConnection = conn;
    }

    /**
     *
     * @return
     */
    @JRubyMethod
    public IRubyObject dispose() {
        // System.out.println("============== dispose called");
        Ruby runtime = getRuntime();

        if (sqlConnection == null) {
            return runtime.getFalse();
        }

        try {
            if (sqlConnection.isClosed()) {
                return runtime.getFalse();
            }
        } catch (SQLException ignored) {
        }

        JDBCUtil.close(sqlConnection);
        sqlConnection = null;
        return runtime.getTrue();
    }

    // ------------------------------------------------ ADDITIONAL JRUBY METHODS

    /**
     *
     * @param value
     * @return
     */
    @JRubyMethod(required = 1)
    public IRubyObject quote_string(final IRubyObject value) {
        String quoted = driver.quoteString(value.asJavaString());
        return getRuntime().newString(quoted);
    }

    /**
     *
     * @param value
     * @return
     */
    @JRubyMethod(required = 1)
    public IRubyObject quote_byte_array(final IRubyObject value) {
        String quoted = driver.quoteByteArray(this, value);
        return getRuntime().newString(quoted);
    }

    /**
     * @{@inheritDoc}
     */
    @JRubyMethod
    @Override
    public IRubyObject inspect() {
        StringBuilder sb = new StringBuilder();

        String cname = getMetaClass().getRealClass().getName();
        sb.append("#<").append(cname).append(":0x");
        sb.append(Integer.toHexString(System.identityHashCode(this)));

        // display both @uri ivar and internal JDBC URI
        sb.append(" @uri=").append(api.getInstanceVariable(this, "@uri").inspect());
        sb.append(" (jdbc_uri=");
        appendQuoted(sb, connectionUri.toString());
        sb.append(")");

        // inspecting @__pool is noisy, for now turn it off
        // sb.append("@__pool=").append(api.getInstanceVariable(this, "@__pool").inspect());

        if (driver.supportsConnectionEncodings()) {
            sb.append(", @encoding=").append(api.getInstanceVariable(this, "@encoding").inspect());
        }
        sb.append(">");
        return getRuntime().newString(sb.toString());
    }

    /**
     * Returns the JDBC URI used internally.
     *
     * Not part of the DataObjects API. This is an implementation-specific
     * method that is provided for inspection and debugging from Ruby code.
     *
     * @return the JDBC URI used internally
     */
    @JRubyMethod(name = "_jdbc_uri", visibility = Visibility.PRIVATE)
    public IRubyObject jdbc_uri() {
        return getRuntime().newString(connectionUri.toString());
    }

    // ------------------------------------------------- PUBLIC JAVA API METHODS

    /**
     *
     * @return
     */
    public java.sql.Connection getInternalConnection() {
        return sqlConnection;
    }

    // -------------------------------------------------- PRIVATE HELPER METHODS

    /**
     * Convert a query string (e.g.
     * driver=org.postgresql.Driver&protocol=postgresql) to a Map of values.
     *
     * @param query
     * @return
     * @throws UnsupportedEncodingException
     */
    private static Map<String, String> parseQueryString(final String query)
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
