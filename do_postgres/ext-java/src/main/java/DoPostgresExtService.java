import data_objects.drivers.DriverDefinition;
import do_postgres.PostgresDriverDefinition;

public class DoPostgresExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new PostgresDriverDefinition();
    public final static String RUBY_MODULE_NAME = "Postgres";
    public final static String RUBY_ERROR_NAME = "PostgresError";

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
