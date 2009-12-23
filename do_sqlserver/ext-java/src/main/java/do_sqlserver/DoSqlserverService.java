package do_sqlserver;

import data_objects.drivers.AbstractDataObjectsService;
import data_objects.drivers.DriverDefinition;

// this class must be named DoSqlserverService (and not DoSqlServerService)
// for the extension to be loaded correctly (alternatively, we could add an
// underscore to the extension JAR name).
public class DoSqlserverService extends AbstractDataObjectsService {

    private final static DriverDefinition driver = new SqlServerDriverDefinition();

    /**
     *
     * @return
     */
    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
