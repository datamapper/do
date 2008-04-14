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
public class Transaction extends RubyObject {
    
    public final static String RUBY_CLASS_NAME = "Transaction";

    private final static ObjectAllocator TRANSACTION_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Transaction instance = new Transaction(runtime, klass);
            return instance;
        }
    };
    
    public static RubyClass createTransactionClass(Ruby runtime, RubyModule jdbcModule) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyClass transactionClass = runtime.defineClassUnder("Transaction",
                superClass, TRANSACTION_ALLOCATOR, jdbcModule);

        transactionClass.defineAnnotatedMethods(Transaction.class);
        return transactionClass;
    }
    
    private Transaction(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }
    
    // Transaction Class
    @JRubyMethod(name = "initialize", required = 1)
    public static IRubyObject t_initialize_p(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }

    @JRubyMethod(name = "commit", required = 0)
    public static IRubyObject commit_p(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }

    @JRubyMethod(name = "rollback", required = 1)
    public static IRubyObject rollback_p(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }

    @JRubyMethod(name = "save", required = 1)
    public static IRubyObject save_p(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }

    //@JRubyMethod(name = "create_command", required = -1)
    //public static IRubyObject create_command_p(IRubyObject recv) {
    //    return recv.getRuntime().getFalse();
    //}

}
