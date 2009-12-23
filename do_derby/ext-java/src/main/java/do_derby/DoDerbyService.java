package do_derby;

import data_objects.drivers.AbstractDataObjectsService;
import data_objects.drivers.DriverDefinition;

public class DoDerbyService extends AbstractDataObjectsService {

    private final static DriverDefinition driver = new DerbyDriverDefinition();

    /**
     *
     * @return
     */
    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
