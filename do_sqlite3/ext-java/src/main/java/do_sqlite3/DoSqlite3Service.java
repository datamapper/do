package do_sqlite3;

import data_objects.drivers.AbstractDataObjectsService;
import data_objects.drivers.DriverDefinition;

public class DoSqlite3Service extends AbstractDataObjectsService {

    private final static DriverDefinition driver = new Sqlite3DriverDefinition();

    /**
     *
     * @return
     */
    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
