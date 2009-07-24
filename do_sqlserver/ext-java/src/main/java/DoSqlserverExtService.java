import data_objects.drivers.DriverDefinition;
import do_sqlserver.SqlServerDriverDefinition;

// this class must be named DoSqlserverExtService (and not DoSqlServerExtService)
// for the extension to be loaded correctly (alternatively, we could add an
// underscore to the extension JAR name).
public class DoSqlserverExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new SqlServerDriverDefinition();

    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
