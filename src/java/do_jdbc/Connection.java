package do_jdbc;

import java.net.URISyntaxException;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import static do_jdbc.DataObjects.DATA_OBJECTS_MODULE_NAME;

/**
 * Connection Class
 * 
 * @author alexbcoles
 */
public class Connection extends RubyObject {

    public final static String RUBY_CLASS_NAME = "Connection";
    
    private java.sql.Connection conn;

    private final static ObjectAllocator CONNECTION_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Connection instance = new Connection(runtime, klass);
            return instance;
        }
    };
    
    public static RubyClass createConnectionClass(Ruby runtime, RubyModule jdbcModule) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyClass connectionClass =
                jdbcModule.defineClassUnder(RUBY_CLASS_NAME,
                superClass, CONNECTION_ALLOCATOR);

        connectionClass.defineAnnotatedMethods(Connection.class);
        return connectionClass;
    }
    
    private Connection(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }
    
    @JRubyMethod(required = 1)
    public static IRubyObject initialize(IRubyObject recv, IRubyObject uri) {
        Ruby runtime = recv.getRuntime();

        // Convert a DM URI (Addressable::URI) to a JDBC URI
        String fullUri = uri.callMethod(runtime.getCurrentContext(), "to_s").toString();
        String protocol = uri.callMethod(runtime.getCurrentContext(), "scheme").toString();
        String host = uri.callMethod(runtime.getCurrentContext(), "host").toString();
        String port = uri.callMethod(runtime.getCurrentContext(), "port").toString();
        String path = uri.callMethod(runtime.getCurrentContext(), "path").toString();
        String user = uri.callMethod(runtime.getCurrentContext(), "user").toString();
        String pass = uri.callMethod(runtime.getCurrentContext(), "password").toString();
        
        System.out.println(fullUri);
        try {
            System.out.println(new java.net.URI(fullUri).toString());
        } catch (URISyntaxException ex) {
            Logger.getLogger(Connection.class.getName()).log(Level.SEVERE, null, ex);
        }
        
        String jdbcUrl;
        java.sql.Connection conn;
        
        //jdbcUrl = "jdbc:" + protocol + ":" + url;
        try {
            conn = DriverManager.getConnection(fullUri, user, pass);
            //java.sql.Connection conn = getConnection(recv);
        } catch (SQLException ex) {
           Logger.getLogger(Connection.class.getName()).log(Level.SEVERE, null, ex);
        }
       //java.sql.Connection conn = getConnection(recv);

        return runtime.getTrue();
    }
    
    @JRubyMethod
    public static IRubyObject real_close(IRubyObject recv) {
        Ruby runtime = recv.getRuntime();
        
        java.sql.Connection prev = getConnection(recv);
        if (prev != null) {
            try {
                prev.close();
            } catch(Exception e) {}
        }
        
        return runtime.getTrue();
    }
    
    private static java.sql.Connection getConnection(IRubyObject recv) {
        java.sql.Connection conn = (java.sql.Connection) recv.dataGetStruct();
        return conn;
    }
    
}