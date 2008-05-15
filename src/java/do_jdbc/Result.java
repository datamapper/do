package do_jdbc;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import static do_jdbc.DataObjects.DATA_OBJECTS_MODULE_NAME;

/**
 * Result Class
 * 
 * @author alexbcoles
 */
public class Result extends RubyObject {
    
    public final static String RUBY_CLASS_NAME = "Result";

    private final static ObjectAllocator RESULT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Result instance = new Result(runtime, klass);
            return instance;
        }
    };

    public static RubyClass createResultClass(Ruby runtime, RubyModule jdbcModule) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyClass resultClass = jdbcModule.defineClassUnder(RUBY_CLASS_NAME, 
               superClass, RESULT_ALLOCATOR);
        resultClass.defineAnnotatedMethods(Result.class);
        return resultClass;
    }
    
    private Result(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }
    
    // inherit initialize
}
