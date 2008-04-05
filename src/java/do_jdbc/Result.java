/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package do_jdbc;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

/**
 *
 * @author alexbcoles
 */

// Result Class
public class Result extends RubyObject {

    public static RubyClass createResultClass(Ruby runtime) {
        RubyClass resultClass = DoJdbcAdapterService.createDoJdbcClass(runtime,
                "Result",
                DoJdbcAdapterService.cDO_Result,
                RESULT_ALLOCATOR);
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
