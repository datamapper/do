package do_sqlserver;

import data_objects.drivers.AbstractDataObjectsExtService;
import data_objects.drivers.DriverDefinition;

// this class must be named DoSqlserverExtService (and not DoSqlServerExtService)
// for the extension to be loaded correctly (alternatively, we could add an
// underscore to the extension JAR name).
public class DoSqlserverExtService extends AbstractDataObjectsExtService {

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
