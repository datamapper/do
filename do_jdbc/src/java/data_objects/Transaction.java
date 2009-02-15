package data_objects;

import data_objects.drivers.DriverDefinition;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyObjectAdapter;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;

/**
 * Transaction Class
 *
 * @author alexbcoles
 * @author mkristian
 */
@JRubyClass(name = "Transaction")
public class Transaction extends RubyObject {

    public final static String RUBY_CLASS_NAME = "Transaction";
    private static RubyObjectAdapter api;
    private static DriverDefinition driver;
    private static String moduleName;
    private static String errorName;

    private final static ObjectAllocator TRANSACTION_ALLOCATOR = new ObjectAllocator() {

        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Transaction instance = new Transaction(runtime, klass);
            return instance;
        }
    };

    public static RubyClass createTransactionClass(final Ruby runtime,
            final String moduleName, final String errorName,
            final DriverDefinition driverDefinition) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyModule driverModule = (RubyModule) doModule.getConstant(moduleName);
        RubyClass transactionClass = runtime.defineClassUnder("Transaction",
                superClass, TRANSACTION_ALLOCATOR, driverModule);
        Transaction.api = JavaEmbedUtils.newObjectAdapter();
        Transaction.driver = driverDefinition;
        Transaction.moduleName = moduleName;
        Transaction.errorName = errorName;
        transactionClass.defineAnnotatedMethods(Transaction.class);
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
     * @param recv
     * @return
     */
    @JRubyMethod
    public static IRubyObject commit(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }

    /**
     * Rollsback the transaction
     *
     * @param recv
     * @return
     */
    @JRubyMethod(required = 1)
    public static IRubyObject rollback(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }

    /**
     * Creates a savepoint for rolling back later
     *
     * @param recv
     * @return
     */
    @JRubyMethod(required = 1)
    public static IRubyObject save(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }

    @JRubyMethod
    public static IRubyObject create_command(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }
}
