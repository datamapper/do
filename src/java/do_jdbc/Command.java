/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

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
 *
 * @author alexbcoles
 */
public class Command extends RubyObject {
    
    public final static String RUBY_CLASS_NAME = "Command";

    private final static ObjectAllocator COMMAND_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Command instance = new Command(runtime, klass);
            return instance;
        }
    };
    
    public static RubyClass createCommandClass(Ruby runtime, RubyModule jdbcModule) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyClass commandClass = runtime.defineClassUnder("Command",
                superClass, COMMAND_ALLOCATOR, jdbcModule);

        // Command Class
        // rb_include_module(cCommand, cDO_Quoting);
        commandClass.defineAnnotatedMethods(Command.class);
        return commandClass;
    }
    
    private Command(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }
    
    @JRubyMethod(name = "set_types", required = 1)
    public static IRubyObject set_types_p(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }

    //@JRubyMethod(name = "execute_non_query", required = -1)
    //public static IRubyObject execute_non_query_p(IRubyObject recv) {
    //    return recv.getRuntime().getFalse();
    //}

    //@JRubyMethod(name = "execute_reader", required = -1)
    //public static IRubyObject execute_reader_p(IRubyObject recv) {
    //    return recv.getRuntime().getFalse();
    //}

    //@JRubyMethod(name = "quote_string", required = -1)
    //public static IRubyObject quote_string_p(IRubyObject recv) {
    //    return recv.getRuntime().getFalse();
   // }
    
}
