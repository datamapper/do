package do_postgres;

import data_objects.drivers.AbstractDataObjectsService;
import data_objects.drivers.DriverDefinition;

public class DoPostgresService extends AbstractDataObjectsService {

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
