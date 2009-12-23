package do_mysql;

import data_objects.drivers.AbstractDataObjectsService;
import data_objects.drivers.DriverDefinition;

public class DoMysqlService extends AbstractDataObjectsService {

    private final static DriverDefinition driver = new MySqlDriverDefinition();

    /**
     *
     * @return
     */
    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
