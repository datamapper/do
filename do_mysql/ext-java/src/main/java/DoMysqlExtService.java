import data_objects.drivers.DriverDefinition;
import do_mysql.MySqlDriverDefinition;

public class DoMysqlExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new MySqlDriverDefinition();

    /**
     *
     * @return
     */
    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
