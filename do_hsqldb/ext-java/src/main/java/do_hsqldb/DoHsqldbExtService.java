package do_hsqldb;

import data_objects.drivers.AbstractDataObjectsExtService;
import data_objects.drivers.DriverDefinition;

public class DoHsqldbExtService extends AbstractDataObjectsExtService {

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
