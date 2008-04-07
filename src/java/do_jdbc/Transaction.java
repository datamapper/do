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

/**
 *
 * @author alexbcoles
 */
public class Transaction extends RubyObject {
    
    public final static String RUBY_CLASS_NAME = "Transaction";

    public static RubyClass createTransactionClass(Ruby runtime, RubyModule module) {
        RubyClass superClass = runtime.getModule("DataObjects").getClass(RUBY_CLASS_NAME);
        RubyClass transactionClass = runtime.defineClassUnder("Transaction", 
                superClass, TRANSACTION_ALLOCATOR, module);
        transactionClass.defineAnnotatedMethods(Transaction.class);
        return transactionClass;
    }
    
    private static ObjectAllocator TRANSACTION_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Transaction instance = new Transaction(runtime, klass);
            return instance;
        }
    };
    
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

    @JRubyMethod(name = "create_command", required = -1)
    public static IRubyObject create_command_p(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }

}
