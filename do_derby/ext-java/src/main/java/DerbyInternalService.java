import data_objects.drivers.DriverDefinition;
import do_derby.DerbyDriverDefinition;

public class DerbyInternalService extends AbstractDataObjectsInternalService {

    private final static DriverDefinition driver = new DerbyDriverDefinition();
    public final static String RUBY_MODULE_NAME = "Derby";

    public String getModuleName() {
        return RUBY_MODULE_NAME;
    }

    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
