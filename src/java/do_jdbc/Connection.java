package do_jdbc;

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
    
    @JRubyMethod(name = "initialize", required = 1)
    public static IRubyObject initialize_p(IRubyObject recv) {
        
        
        
        return recv.getRuntime().getFalse();
    }

    @JRubyMethod(name = "using_socket?", required = 0)
    public static IRubyObject using_socket_p(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }
    
    @JRubyMethod(name = "character_set", required = 0)
    public static IRubyObject character_set_p(IRubyObject recv) {
        String charSet = "iso-9292";
        return recv.getRuntime().newString(charSet);
    }
    
    @JRubyMethod(name = "real_close", required = 0)
    public static IRubyObject real_close_p(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }
     
    @JRubyMethod(name = "begin_transaction", required = 0)
    public static IRubyObject begin_transaction_p(IRubyObject recv) {
        
        return recv;
         //return recv.getRuntime().getFalse();
    }
    
}