package do_postgres;

import data_objects.drivers.AbstractDataObjectsExtService;
import data_objects.drivers.DriverDefinition;

public class DoPostgresExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new PostgresDriverDefinition();

    /**
     *
     * @return
     */
    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
