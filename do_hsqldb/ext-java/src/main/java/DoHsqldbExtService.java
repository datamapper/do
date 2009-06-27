import data_objects.drivers.DriverDefinition;
import do_hsqldb.HsqldbDriverDefinition;

public class DoHsqldbExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new HsqldbDriverDefinition();

    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
