package do_jdbc;

import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyObjectAdapter;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import static do_jdbc.DataObjects.DATA_OBJECTS_MODULE_NAME;

/**
 * Reader Class
 * 
 * @author alexbcoles
 */
@JRubyClass(name = "Reader")
public class Reader extends RubyObject {
    
    private static RubyObjectAdapter rubyApi;
    public final static String RUBY_CLASS_NAME = "Reader";

    private final static ObjectAllocator READER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Reader instance = new Reader(runtime, klass);
            return instance;
        }
    };
    
    public static RubyClass createReaderClass(Ruby runtime, RubyModule jdbcModule) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyClass readerClass = jdbcModule.defineClassUnder(RUBY_CLASS_NAME, 
                superClass, READER_ALLOCATOR);
        readerClass.defineAnnotatedMethods(Reader.class);
        rubyApi = JavaEmbedUtils.newObjectAdapter();
        return readerClass;
    }
    
    private Reader(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }
    
    @JRubyMethod(name = "initialize", required = 2) 
    public static IRubyObject initialize(IRubyObject recv) {
        return recv;
    }
    
    //
    // @result = result
    // @meta_data = result.meta_data
    // @types = types || java_types_to_ruby_types(@meta_data)
    //
    
    @JRubyMethod
    public static IRubyObject close(IRubyObject recv) {
        Ruby runtime = recv.getRuntime();
        Reader reader = (Reader) rubyApi.getInstanceVariable(recv, "@reader");
        
        if (!reader.isNil()) {
            // TODO:
            // CLOSE THE READER IN JAVA
            //
            // rs.close();
            // 
            reader = (Reader) rubyApi.setInstanceVariable(recv, "@reader", runtime.getNil());
            return runtime.getTrue();
        } else {
            return runtime.getFalse();
        }
    }

    /**
     * Moves the cursor forward.
     * 
     * @param recv
     * @return
     */
    @JRubyMethod(name = "next!")
    public static IRubyObject next(IRubyObject recv) {
        // @in_row = (@result.next || nil)
        IRubyObject result_next = rubyApi.getInstanceVariable(recv, "@result.next");
        // recv.getRuntime().getNil();
        IRubyObject in_row = rubyApi.setInstanceVariable(recv, "@in_row", result_next);
        
       // ResultSet rs = null;
       // rs.next();
        
        return in_row;
    }

    @JRubyMethod
    public static IRubyObject values(IRubyObject recv) {
       Ruby runtime = recv.getRuntime();
       IRubyObject state = rubyApi.getInstanceVariable(recv, "@state");
        
       //raise "error" unless @in_row
       if ( state.isNil() || state.convertToInteger().getLongValue() == 0) // change this to row index
       {
           // Make a SLIT
           throw runtime.newStandardError("Reader is not initialized");
       }
       IRubyObject values = rubyApi.getInstanceVariable(recv, "@values");
       return values;
    }

    @JRubyMethod
    public static IRubyObject fields(IRubyObject recv) {
        IRubyObject fields = rubyApi.getInstanceVariable(recv, "@fields");
        return fields;
    }
    
}
