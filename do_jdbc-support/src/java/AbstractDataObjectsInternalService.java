
import data_objects.Command;
import data_objects.Connection;
import data_objects.Reader;
import data_objects.Result;
import data_objects.Transaction;
import data_objects.drivers.DriverDefinition;
import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.runtime.load.BasicLibraryService;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;

/**
 *
 * thanks to Ola Bini's
 * http://ola-bini.blogspot.com/2006/10/jruby-tutorial-4-writing-java.html
 *
 * @author alexbcoles
 */
public abstract class AbstractDataObjectsInternalService implements BasicLibraryService {

    public static RubyModule doModule;
    public static RubyModule doDriverModule;

    private static RubyClass connection;
    private static RubyClass command;
    private static RubyClass result;
    private static RubyClass reader;
    private static RubyClass transaction;

    public boolean basicLoad(Ruby runtime) throws IOException {

        // Get the DataObjects module
        doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);

        // Define the DataObjects module for this Driver
        // e.g. DataObjects::Derby, DataObjects::MySql
        doDriverModule = doModule.defineModuleUnder(getModuleName());
        
        // Define a JdbcError
        runtime.defineClass("JdbcError", runtime.getStandardError(), runtime.getStandardError().getAllocator());

        // Define the DataObjects driver classes
        DriverDefinition driverDefinition = getDriverDefinition();
        
        command = Command.createCommandClass(runtime, doDriverModule, driverDefinition);
        connection = Connection.createConnectionClass(runtime, doDriverModule, driverDefinition);
        result = Result.createResultClass(runtime, doDriverModule, driverDefinition);
        reader = Reader.createReaderClass(runtime, doDriverModule, driverDefinition);
        transaction = Transaction.createTransactionClass(runtime, doDriverModule, driverDefinition);

        return true;
    }

    public abstract String getModuleName();
    
    public abstract DriverDefinition getDriverDefinition();
    
}