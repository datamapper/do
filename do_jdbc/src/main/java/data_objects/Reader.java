package data_objects;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;
import static data_objects.util.StringUtil.appendJoined;
import static data_objects.util.StringUtil.appendJoinedAndQuoted;

import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
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
    private List<String> fieldNames;
    private List<RubyType> fieldTypes;
    private int fieldCount;
    private boolean opened = false;

    private final static ObjectAllocator READER_ALLOCATOR = new ObjectAllocator() {

        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            return new Reader(runtime, klass);
        }
    };

    /**
     *
     * @param runtime
     * @param driver
     * @return
     */
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

    /**
     *
     * @param runtime
     * @param klass
     */
    private Reader(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }

    // -------------------------------------------------- DATAOBJECTS PUBLIC API

    // default initialize

    /**
     *
     * @return
     */
    @JRubyMethod
    public IRubyObject close() {
        Ruby runtime = getRuntime();

        if (resultSet != null) {
            JDBCUtil.close(resultSet);
            resultSet = null;
            opened = false;
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

            RubyArray row = runtime.newArray();
            IRubyObject value;
            int fieldTypesCount = fieldTypes.size();

            try {
                opened = rs.next();

                if (!opened) {
                    return runtime.getFalse();
                }

                for (int i = 0; i < fieldCount; i++) {
                    RubyType type = fieldTypes.get(i);
                    value = driver.getTypecastResultSetValue(runtime, rs, i + 1, type);
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

    /**
     *
     * @return
     */
    @JRubyMethod
    public IRubyObject values() {
        Ruby runtime = getRuntime();

        if (!opened) {
            throw driver.newDriverError(runtime, "Reader is not initialized");
        }
        IRubyObject values = api.getInstanceVariable(this, "@values");
        return (values != null) ? values : runtime.getNil();
    }

    /**
     *
     * @return
     */
    @JRubyMethod
    public IRubyObject fields() {
        RubyArray fields = getRuntime().newArray();
        for (String f : fieldNames) {
            fields.append(getRuntime().newString(f));
        }
        return fields;
    }

    /**
     *
     * @return
     */
    @JRubyMethod
    public IRubyObject field_count() {
        return getRuntime().newFixnum(fieldCount);
    }

    /**
     * @{@inheritDoc}
     */
    @JRubyMethod
    @Override
    public IRubyObject inspect() {
        StringBuilder sb = new StringBuilder();

        String cname = getMetaClass().getRealClass().getName();
        sb.append("#<").append(cname).append(":0x");
        sb.append(Integer.toHexString(System.identityHashCode(this)));

        sb.append(" field_types=[");
        appendJoined(sb, fieldTypes);
        sb.append("], ");
        sb.append("field_count=").append(fieldCount).append(", ");
        sb.append("opened=").append(opened).append(", ");
        sb.append("fields=[");
        appendJoinedAndQuoted(sb, fieldNames);
        sb.append("]");

        sb.append(">");

        return getRuntime().newString(sb.toString());
    }

    // ------------------------------------------------- PUBLIC JAVA API METHODS

    /**
     *
     * @return
     */
    public ResultSet getResultSet() {
        return resultSet;
    }

    /**
     *
     * @param resultSet
     */
    public void setResultset(ResultSet resultSet) {
        this.resultSet = resultSet;
    }

    public void setFields(List<String> fields) {
        this.fieldNames = fields;
    }

    public void setFieldTypes(List<RubyType> fieldTypes) {
        this.fieldTypes = fieldTypes;
    }

    public void setFieldCount(int count) {
        this.fieldCount = count;
    }

}
