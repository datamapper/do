package do_mysql;

import data_objects.drivers.AbstractDataObjectsExtService;
import data_objects.drivers.DriverDefinition;

public class DoMysqlExtService extends AbstractDataObjectsExtService {

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
