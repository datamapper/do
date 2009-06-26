import data_objects.drivers.DriverDefinition;
import do_postgres.PostgresDriverDefinition;

public class DoPostgresExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new PostgresDriverDefinition();

    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
