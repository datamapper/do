/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package do_jdbc;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

/**
 *
 * @author alexbcoles
 */
public class Reader extends RubyObject {

    public static RubyClass createReaderClass(Ruby runtime) {
        RubyClass readerClass = DoJdbcInternalService.createDoJdbcClass(
                runtime,
                "Reader",
                DoJdbcInternalService.DO_Reader,
                READER_ALLOCATOR);
        readerClass.defineAnnotatedMethods(Reader.class);
        return readerClass;
    }
    
    private static ObjectAllocator READER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Reader instance = new Reader(runtime, klass);
            return instance;
        }
    };
    
    private Reader(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }
    
        // Reader Class
    @JRubyMethod(name = "close", required = 0)
    public static IRubyObject close_p(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }

    @JRubyMethod(name = "next!", required = 0)
    public static IRubyObject next_p(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }

    @JRubyMethod(name = "values", required = 0)
    public static IRubyObject values_p(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }

    @JRubyMethod(name = "fields", required = 0)
    public static IRubyObject fields_p(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }
    
}
