package data_objects;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import java.sql.Connection;
import java.sql.SQLException;

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

    // -------------------------------------------------- DATAOBJECTS PUBLIC API

    // inherit initialize

    /**
     * Begins the transaction
     *
     * @return
     */
    @JRubyMethod
    public IRubyObject begin() {
        java.sql.Connection conn = getConnection();
        try {
            conn.setAutoCommit(false);
        } catch (SQLException sqle) {
            throw driver.newDriverError(getRuntime(), sqle);
        }
        return getRuntime().getTrue();
    }

    /**
     * Commits the transaction
     *
     * @return
     */
    @JRubyMethod
    public IRubyObject commit() {
        java.sql.Connection conn = getConnection();
        try {
            conn.commit();
        } catch (SQLException sqle) {
            throw driver.newDriverError(getRuntime(), sqle);
        } finally {
            try {
                conn.setAutoCommit(true);
            } catch (SQLException sqle) {
                throw driver.newDriverError(getRuntime(), sqle);
            }
        }
        return getRuntime().getTrue();
    }

    /**
     * Rollsback the transaction
     *
     * @return
     */
    @JRubyMethod
    public IRubyObject rollback() {
        java.sql.Connection conn = getConnection();
        try {
            conn.rollback();
        } catch (SQLException sqle) {
            throw driver.newDriverError(getRuntime(), sqle);
        } finally {
            try {
                conn.setAutoCommit(true);
            } catch (SQLException sqle) {
                throw driver.newDriverError(getRuntime(), sqle);
            }
        }
        return getRuntime().getTrue();
    }

    // ---------------------------------------------------------- HELPER METHODS

    private java.sql.Connection getConnection() {
        Ruby runtime = getRuntime();
        IRubyObject connection_instance = api.getInstanceVariable(this,
                "@connection");
        IRubyObject wrapped_jdbc_connection = api.getInstanceVariable(
                connection_instance, "@connection");
        if (wrapped_jdbc_connection.isNil()) {
            throw driver.newDriverError(runtime,
                    "This connection has already been closed.");
        }
        return (java.sql.Connection) wrapped_jdbc_connection.dataGetStruct();
    }

}
