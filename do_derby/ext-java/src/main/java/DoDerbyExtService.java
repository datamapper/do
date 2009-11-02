import data_objects.drivers.DriverDefinition;
import do_derby.DerbyDriverDefinition;

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
