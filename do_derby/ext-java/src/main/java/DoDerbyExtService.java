import data_objects.drivers.DriverDefinition;
import do_derby.DerbyDriverDefinition;

public class DoDerbyExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new DerbyDriverDefinition();
    public final static String RUBY_MODULE_NAME = "Derby";
    public final static String RUBY_ERROR_NAME = "DerbyError";

    public String getModuleName() {
        return RUBY_MODULE_NAME;
    }

    @Override
    public String getErrorName() {
        return RUBY_ERROR_NAME;
    }

    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
