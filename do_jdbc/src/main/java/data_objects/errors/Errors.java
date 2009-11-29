package data_objects.errors;

import data_objects.drivers.DriverDefinition;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyModule;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.Block;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Provides factory methods for all of the DataObjects Error types
 *
 * @author alexbcoles
 */
public final class Errors {

    public enum Type {

        SQL_ERROR         ("SQLError"),
        CONNECTION_ERROR  ("ConnectionError"),
        DATA_ERROR        ("DataError"),
        INTEGRITY_ERROR   ("IntegrityError"),
        SYNTAX_ERROR      ("SyntaxError"),
        TRANSACTION_ERROR ("TransactionError");

        private final String rubyName;

        private Type(String rubyName) {
            this.rubyName = rubyName;
        }

        public String getRubyName() {
            return rubyName;
        }

        @Override
        public String toString() {
            return rubyName;
        }
    }

    public static RaiseException newConnectionError(Ruby runtime, String message) {
        RubyModule doModule = runtime.fastGetModule(DATA_OBJECTS_MODULE_NAME);
        return newError(runtime, doModule.getClass(Type.CONNECTION_ERROR.getRubyName()), message);
    }

    public static RaiseException newDataError(Ruby runtime, String message) {
        RubyModule doModule = runtime.fastGetModule(DATA_OBJECTS_MODULE_NAME);
        return newError(runtime, doModule.getClass(Type.DATA_ERROR.getRubyName()), message);
    }

    public static RaiseException newQueryError(Ruby runtime,
            DriverDefinition driver,
            SQLException sqle,
            Statement statement) {
        // TODO: provide an option to display extended debug information, for
        // driver developers, etc. Otherwise, keep it off to keep noise down for
        // end-users.
        Pattern p = Pattern.compile("Statement parameter (\\d+) not set.");
                     // POSTGRES:   "No value specified for parameter 1."
                     // SQLITE3:    NO EXCEPTION THROWN!
                     // H2:         Parameter #1 is not set     (90012)
                     // HSQLDB:     NO EXCEPTION THROWN!
                     // DERBY:      At least one parameter to the current statement is uninitialized.
                     // DERBY SQL State: 07000
        Matcher m = p.matcher(sqle.getMessage());

        if (m.matches()) {
            return runtime.newArgumentError("Binding mismatch: 0 for " + m.group(1));
        } else {
            return newSqlError(runtime, driver, sqle, statement);
        }
    }

    public static RaiseException newSqlError(Ruby runtime,
            DriverDefinition driver,
            String message) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass driverError = doModule.getClass(Type.SQL_ERROR.getRubyName());
        RubyException doSqlError = (RubyException) driverError.newInstance(
                runtime.getCurrentContext(),
                new IRubyObject[]{
                    runtime.newString(message)
                },
                Block.NULL_BLOCK);

        return new RaiseException(doSqlError);
    }

    public static RaiseException newSqlError(Ruby runtime,
            DriverDefinition driver,
            SQLException exception) {
        return newSqlError(runtime, driver, exception, null);
    }

    public static RaiseException newSqlError(Ruby runtime,
            DriverDefinition driver, SQLException exception,
            java.sql.Statement statement) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass driverError = doModule.getClass(Type.SQL_ERROR.getRubyName());

        String message = exception.getLocalizedMessage();
        int code = exception.getErrorCode();
        String sqlState = exception.getSQLState();
        String query = "";
        String uri = null;      // TODO: implement me

        if (statement != null)
            query = driver.statementToString(statement);

        RubyException doSqlError = (RubyException) driverError.newInstance(
                runtime.getCurrentContext(),
                new IRubyObject[]{
                    runtime.newString(message),
                    runtime.newFixnum(code),
                    (sqlState != null) ? runtime.newString(sqlState) : runtime.getNil(),
                    runtime.newString(query),
                    (uri != null) ? runtime.newString(uri) : runtime.getNil()
                },
                Block.NULL_BLOCK);

        return new RaiseException(doSqlError);
    }

    public static RaiseException newError(Ruby runtime, RubyClass errorClass, String message) {
        return new RaiseException(runtime, errorClass, message, true);
    }

    /**
     * Private constructor
     */
    private Errors() {
    }

}
