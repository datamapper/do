/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package do_jdbc;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

/**
 *
 * @author alexbcoles
 */

// Result Class
public class Result extends RubyObject {
    
    public final static String RUBY_CLASS_NAME = "Result";

    public static RubyClass createResultClass(RubyModule module, RubyClass superClass) {
        RubyClass resultClass = module.defineClassUnder(RUBY_CLASS_NAME, 
                superClass, RESULT_ALLOCATOR);
        //resultClass.defineAnnotatedMethods(Result.class);
        return resultClass;
    }
    
    private static ObjectAllocator RESULT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Result instance = new Result(runtime, klass);
            return instance;
        }
    };

    private Result(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }
}
