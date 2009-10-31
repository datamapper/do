import data_objects.drivers.DriverDefinition;
import do_h2.H2DriverDefinition;

public class DoH2ExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new H2DriverDefinition();

    /**
     * 
     * @return
     */
    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
