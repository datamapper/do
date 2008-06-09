package data_objects.drivers;

/**
 *
 * @author alexbcoles
 */
public abstract class AbstractDriverDefinition implements DriverDefinition {

    public abstract boolean supportsJdbcGeneratedKeys();

}
