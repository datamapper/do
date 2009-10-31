import data_objects.drivers.DriverDefinition;
import do_oracle.OracleDriverDefinition;

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
