import data_objects.drivers.DriverDefinition;
import do_sqlite3.Sqlite3DriverDefinition;

public class DoSqlite3ExtService extends AbstractDataObjectsExtService {

    private final static DriverDefinition driver = new Sqlite3DriverDefinition();
    public final static String RUBY_MODULE_NAME = "Sqlite3";
    public final static String RUBY_ERROR_NAME = "Sqlite3Error";

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
