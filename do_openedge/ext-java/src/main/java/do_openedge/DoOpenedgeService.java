package do_openedge;

import data_objects.drivers.AbstractDataObjectsService;
import data_objects.drivers.DriverDefinition;

public class DoOpenedgeService extends AbstractDataObjectsService {

    private final static DriverDefinition driver = new OpenEdgeDriverDefinition();

    /**
     *
     * @return
     */
    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
