package data_objects;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import data_objects.drivers.DriverDefinition;

/**
 * Transaction Class
 * 
 * @author alexbcoles
 * @author mkristian
 */
@SuppressWarnings("serial")
@JRubyClass(name = "Transaction")
public class Transaction extends DORubyObject {

    public final static String RUBY_CLASS_NAME = "Transaction";

    private final static ObjectAllocator TRANSACTION_ALLOCATOR = new ObjectAllocator() {

        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Transaction instance = new Transaction(runtime, klass);
            return instance;
        }
    };

    public static RubyClass createTransactionClass(final Ruby runtime,
            DriverDefinition driver) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyModule driverModule = (RubyModule) doModule.getConstant(driver
                .getModuleName());
        RubyClass transactionClass = runtime.defineClassUnder("Transaction",
                superClass, TRANSACTION_ALLOCATOR, driverModule);
        transactionClass.defineAnnotatedMethods(Transaction.class);
        setDriverDefinition(transactionClass, runtime, driver);
        return transactionClass;
    }

    private Transaction(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }

    @JRubyMethod(required = 1)
    public static IRubyObject initialize(IRubyObject recv) {
        return recv;
    }

    /**
     * Commits the transaction
     * 
     * @return
     */
    @JRubyMethod
    public IRubyObject commit() {
        return getRuntime().getFalse();
    }

    /**
     * Rollsback the transaction
     * 
     * @return
     */
    @JRubyMethod(required = 1)
    public IRubyObject rollback() {
        return getRuntime().getFalse();
    }

    /**
     * Creates a savepoint for rolling back later
     * 
     * @return
     */
    @JRubyMethod(required = 1)
    public IRubyObject save() {
        return getRuntime().getFalse();
    }

    @JRubyMethod
    public IRubyObject create_command() {
        return getRuntime().getFalse();
    }
}
