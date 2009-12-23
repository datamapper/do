package data_objects.drivers;


import data_objects.Command;
import data_objects.Connection;
import data_objects.Reader;
import data_objects.Result;
import data_objects.Transaction;
import data_objects.drivers.DriverDefinition;
import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.RubyModule;
import org.jruby.runtime.load.BasicLibraryService;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;

/**
 * AbstractDataObjectsService
 *
 * @author alexbcoles
 */
public abstract class AbstractDataObjectsService implements BasicLibraryService {

    /**
     *
     * @param runtime
     * @return
     * @throws IOException
     */
    public boolean basicLoad(final Ruby runtime) throws IOException {

        final DriverDefinition driver = getDriverDefinition();

        // Get the DataObjects module
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);

        // Define the DataObjects module for this Driver
        // e.g. DataObjects::Derby, DataObjects::MySql
        doModule.defineModuleUnder(driver.getModuleName());

        // Define the DataObjects driver classes
        Command.createCommandClass(runtime, driver);
        Connection.createConnectionClass(runtime, driver);
        Result.createResultClass(runtime, driver);
        Reader.createReaderClass(runtime, driver);
        Transaction.createTransactionClass(runtime, driver);

        return true;
    }

    /**
     *
     * @return
     */
    public abstract DriverDefinition getDriverDefinition();
}
