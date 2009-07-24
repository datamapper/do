import data_objects.drivers.DriverDefinition;
import do_oracle.OracleDriverDefinition;

public class DoOracleExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new OracleDriverDefinition();

    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
