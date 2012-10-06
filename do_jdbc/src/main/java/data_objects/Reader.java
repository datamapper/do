package data_objects;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;
import static data_objects.util.StringUtil.appendJoined;
import static data_objects.util.StringUtil.appendJoinedAndQuoted;

import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
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
import data_objects.errors.Errors;
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
    ResultSet resultSet;
    Statement statement;
    List<String> fieldNames;
    List<RubyType> fieldTypes;
    int fieldCount;
    boolean opened = false;
    RubyArray values;

    private final IRubyObject TRUE;
    private final IRubyObject FALSE;
    private final IRubyObject NIL;

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
        
        IRubyObject readerConstant = driverModule.getConstantAt(RUBY_CLASS_NAME);
        if (readerConstant instanceof RubyClass) {
            return (RubyClass) readerConstant;
        }

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
        TRUE = runtime.getTrue();
        FALSE = runtime.getFalse();
        NIL = runtime.getNil();
    }

    // -------------------------------------------------- DATAOBJECTS PUBLIC API

    // default initialize

    /**
     *
     * @return
     */
    @JRubyMethod
    public IRubyObject close() {
        if (resultSet != null) {
            JDBCUtil.close(resultSet,statement);
            resultSet = null;
            statement = null;
            opened = false;
            return TRUE;
        } else {
            return FALSE;
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
            if (resultSet == null) {
                return FALSE;
            }

            values = runtime.newArray(fieldTypes.size());

            try {
                opened = resultSet.next();

                if (!opened) {
                    return FALSE;
                }
                int i = 1;
                for(RubyType type: fieldTypes){
                    values.append(driver.getTypecastResultSetValue(runtime, resultSet, i++, type));
                }

            } catch (SQLException sqe) {
                JDBCUtil.close(resultSet,statement);
                throw Errors.newSqlError(runtime, driver, sqe);
            } catch (IOException ioe) {
                JDBCUtil.close(resultSet,statement);
                throw Errors.newSqlError(runtime, driver, ioe.getLocalizedMessage());
            }

            //TODO needed on ruby side ?
            //api.setInstanceVariable(this, "@values", values);
            return TRUE;
        } catch (RuntimeException e) {
            JDBCUtil.close(resultSet,statement);
            e.printStackTrace();
            throw Errors.newSqlError(runtime, driver, e.getMessage());
        }
    }

    /**
     *
     * @return
     */
    @JRubyMethod
    public IRubyObject values() {
        if (!opened) {
            JDBCUtil.close(resultSet,statement);
            throw Errors.newDataError(getRuntime(), "Reader is not initialized");
        }

        return values != null ? values : NIL;
    }

    /**
     *
     * @return
     */
    @JRubyMethod
    public IRubyObject fields() {
        RubyArray fields = getRuntime().newArray(fieldNames.size());
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

}
