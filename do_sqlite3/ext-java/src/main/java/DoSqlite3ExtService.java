
import data_objects.drivers.DriverDefinition;
import do_sqlite3.Sqlite3DriverDefinition;

public class DoSqlite3ExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new Sqlite3DriverDefinition();
    
    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
