import data_objects.drivers.DriverDefinition;
import do_mysql.MySqlDriverDefinition;

public class DoMysqlExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new MySqlDriverDefinition();
   
    @Override
    public DriverDefinition getDriverDefinition() {
        return driver;
    }

}
