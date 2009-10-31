package data_objects;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;

import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyNumeric;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import data_objects.drivers.DriverDefinition;
import data_objects.util.JDBCUtil;

/**
 * Reader Class
 *
 * @author alexbcoles
 */
@SuppressWarnings("serial")
@JRubyClass(name = "Reader")
public class Reader extends DORubyObject {

    public final static String RUBY_CLASS_NAME = "Reader";
    private ResultSet resultSet;

    private final static ObjectAllocator READER_ALLOCATOR = new ObjectAllocator() {

        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            return new Reader(runtime, klass);
        }
    };

    public static RubyClass createReaderClass(final Ruby runtime,
            DriverDefinition driver) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyModule driverModule = (RubyModule) doModule.getConstant(driver
                .getModuleName());
        RubyClass readerClass = driverModule.defineClassUnder(RUBY_CLASS_NAME,
                superClass, READER_ALLOCATOR);
        readerClass.defineAnnotatedMethods(Reader.class);
        setDriverDefinition(readerClass, runtime, driver);
        return readerClass;
    }

    private Reader(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }

    // -------------------------------------------------- DATAOBJECTS PUBLIC API

    // default initialize
    @JRubyMethod
    public IRubyObject close() {
        Ruby runtime = getRuntime();

        if (resultSet != null) {
            JDBCUtil.close(resultSet);
            resultSet = null;
            return runtime.getTrue();
        } else {
            return runtime.getFalse();
        }
    }

    /**
     * Moves the cursor forward.
     *
     * @return
     */
    @JRubyMethod(name = "next!")
    public IRubyObject next() {
        Ruby runtime = getRuntime();
        try {
            ResultSet rs = resultSet;

            if (rs == null) {
                return runtime.getFalse();
            }

            IRubyObject field_types = api.getInstanceVariable(this,
                    "@field_types");
            IRubyObject field_count = api.getInstanceVariable(this,
                    "@field_count");
            RubyArray row = runtime.newArray();
            IRubyObject value;
            int fieldTypesCount = field_types.convertToArray().getLength();

            try {
                boolean hasNext = rs.next();
                api.setInstanceVariable(this, "@state", runtime
                        .newBoolean(hasNext));

                if (!hasNext) {
                    return runtime.getFalse();
                }

                for (int i = 0; i < RubyNumeric.fix2int(field_count
                        .convertToInteger()); i++) {
                    int col = i + 1;
                    RubyType type;

                    if (fieldTypesCount > 0) {
                        // use the specified type
                        String typeName = field_types.convertToArray().get(i)
                                .toString();
                        type = RubyType.getRubyType(typeName.toUpperCase());
                    } else {
                        // infer the type

                        // assume the mapping from jdbc type to ruby type to be
                        // complete
                        type = driver.jdbcTypeToRubyType(rs.getMetaData().getColumnType(col),
                            rs.getMetaData().getPrecision(col), rs.getMetaData().getScale(col));

                    }

                    if (type == null)
                        throw runtime
                                .newRuntimeError("Problem automatically mapping JDBC Type to Ruby Type");

                    value = driver.getTypecastResultSetValue(runtime, rs, col,
                            type);
                    row.push_m(new IRubyObject[] { value });
                }
            } catch (SQLException sqe) {
                throw driver.newDriverError(runtime, sqe);
            } catch (IOException ioe) {
                throw driver.newDriverError(runtime, ioe.getLocalizedMessage());
            }

            api.setInstanceVariable(this, "@values", row);
            return runtime.getTrue();
        } catch (RuntimeException e) {
            e.printStackTrace();
            throw driver.newDriverError(runtime, e.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject values() {
        Ruby runtime = getRuntime();
        IRubyObject state = api.getInstanceVariable(this, "@state");

        if (state == null || state.isNil() || !state.isTrue()) {
            throw driver.newDriverError(runtime, "Reader is not initialized");
        }
        IRubyObject values = api.getInstanceVariable(this, "@values");
        return (values != null) ? values : runtime.getNil();
    }

    @JRubyMethod
    public IRubyObject fields() {
        return api.getInstanceVariable(this, "@fields");
    }

    @JRubyMethod
    public IRubyObject field_count() {
        return api.getInstanceVariable(this, "@field_count");
    }

    // ------------------------------------------------- PUBLIC JAVA API METHODS

    public ResultSet getResultSet() {
        return resultSet;
    }

    public void setResultset(ResultSet resultSet) {
        this.resultSet = resultSet;
    }

}
