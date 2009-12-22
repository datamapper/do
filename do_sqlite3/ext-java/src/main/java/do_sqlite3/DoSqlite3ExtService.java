package do_sqlite3;

import data_objects.drivers.AbstractDataObjectsExtService;
import data_objects.drivers.DriverDefinition;

public class DoSqlite3ExtService extends AbstractDataObjectsExtService {

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
