package do_oracle;

import data_objects.drivers.AbstractDataObjectsExtService;
import data_objects.drivers.DriverDefinition;

public class DoOracleExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new OracleDriverDefinition();

    /**
     *
     * @return
     */
    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
