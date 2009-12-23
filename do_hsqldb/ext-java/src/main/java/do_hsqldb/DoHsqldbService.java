package do_hsqldb;

import data_objects.drivers.AbstractDataObjectsService;
import data_objects.drivers.DriverDefinition;

public class DoHsqldbService extends AbstractDataObjectsService {

    private final static DriverDefinition driver = new HsqldbDriverDefinition();

    /**
     *
     * @return
     */
    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
