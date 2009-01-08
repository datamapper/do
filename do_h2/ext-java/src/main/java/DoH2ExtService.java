import data_objects.drivers.DriverDefinition;
import do_h2.H2DriverDefinition;

public class DoH2ExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new H2DriverDefinition();
    public final static String RUBY_MODULE_NAME = "H2";
    public final static String RUBY_ERROR_NAME = "H2Error";

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
