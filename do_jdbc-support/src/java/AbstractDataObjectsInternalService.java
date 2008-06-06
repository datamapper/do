
import data_objects.Command;
import data_objects.Connection;
import data_objects.Reader;
import data_objects.Result;
import data_objects.Transaction;
import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.runtime.load.BasicLibraryService;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;
import static data_objects.DataObjects.JDBC_MODULE_NAME;

/**
 *
 * thanks to Ola Bini's
 * http://ola-bini.blogspot.com/2006/10/jruby-tutorial-4-writing-java.html
 *
 * @author alexbcoles
 */
public class AbstractDataObjectsInternalService implements BasicLibraryService {

    public static RubyModule doModule;
    public static RubyModule doJdbcModule;

    private static RubyClass connection;
    private static RubyClass command;
    private static RubyClass result;
    private static RubyClass reader;
    private static RubyClass transaction;

    public boolean basicLoad(Ruby runtime) throws IOException {

        // Get the ::DataObjects module
        doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);

        // Define the DataObjects::Jdbc module
        doJdbcModule = doModule.defineModuleUnder(JDBC_MODULE_NAME);

        // Define a JdbcError
        runtime.defineClass("JdbcError", runtime.getStandardError(), runtime.getStandardError().getAllocator());

        // Define the DataObjects classes
        command = Command.createCommandClass(runtime, doJdbcModule);
        connection = Connection.createConnectionClass(runtime, doJdbcModule);
        result = Result.createResultClass(runtime, doJdbcModule);
        reader = Reader.createReaderClass(runtime, doJdbcModule);
        transaction = Transaction.createTransactionClass(runtime, doJdbcModule);

        return true;
    }

}