package do_derby;

import data_objects.drivers.AbstractDataObjectsExtService;
import data_objects.drivers.DriverDefinition;

public class DoDerbyExtService extends AbstractDataObjectsExtService {

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
