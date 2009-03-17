package data_objects;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;

import java.sql.SQLException;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import data_objects.drivers.DriverDefinition;
import data_objects.errors.Errors;
import data_objects.util.JDBCUtil;

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
            return new Transaction(runtime, klass);
        }
    };

    /**
     *
     * @param runtime
     * @param driver
     * @return
     */
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

    /**
     *
     * @param runtime
     * @param klass
     */
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
            JDBCUtil.close(conn);
            throw Errors.newSqlError(getRuntime(), driver, sqle);
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
            JDBCUtil.close(conn);
            throw Errors.newSqlError(getRuntime(), driver, sqle);
        } finally {
            try {
                conn.setAutoCommit(true);
            } catch (SQLException sqle) {
                JDBCUtil.close(conn);
                throw Errors.newSqlError(getRuntime(), driver, sqle);
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
            JDBCUtil.close(conn);
            throw Errors.newSqlError(getRuntime(), driver, sqle);
        } finally {
            try {
                conn.setAutoCommit(true);
            } catch (SQLException sqle) {
                JDBCUtil.close(conn);
                throw Errors.newSqlError(getRuntime(), driver, sqle);
            }
        }
        return getRuntime().getTrue();
    }

    // ---------------------------------------------------------- HELPER METHODS

    /**
     *
     * @return
     */
    private java.sql.Connection getConnection() {
        Connection connection_instance = (Connection) api.getInstanceVariable(this,
                "@connection");
        java.sql.Connection conn = connection_instance.getInternalConnection();
        try {
            if (conn == null || conn.isClosed()) {
                throw Errors.newConnectionError(getRuntime(), "This connection has already been closed.");
            }
        } catch (SQLException ignored) {
        //TODO log this
        }

        return conn;
    }

}
