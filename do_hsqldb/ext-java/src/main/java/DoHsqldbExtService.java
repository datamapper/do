import data_objects.drivers.DriverDefinition;
import do_hsqldb.HsqldbDriverDefinition;

public class DoHsqldbExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new HsqldbDriverDefinition();
    public final static String RUBY_MODULE_NAME = "Hsqldb";
    public final static String RUBY_ERROR_NAME = "HsqldbError";

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
