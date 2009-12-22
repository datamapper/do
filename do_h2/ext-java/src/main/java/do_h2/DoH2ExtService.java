package do_h2;

import data_objects.drivers.AbstractDataObjectsExtService;
import data_objects.drivers.DriverDefinition;

public class DoH2ExtService extends AbstractDataObjectsExtService {

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
