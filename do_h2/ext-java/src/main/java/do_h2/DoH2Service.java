package do_h2;

import data_objects.drivers.AbstractDataObjectsService;
import data_objects.drivers.DriverDefinition;

public class DoH2Service extends AbstractDataObjectsService {

    private final static DriverDefinition driver = new H2DriverDefinition();

    /**
     *
     * @return
     */
    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
