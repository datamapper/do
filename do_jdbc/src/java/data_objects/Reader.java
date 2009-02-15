package data_objects;

import data_objects.drivers.DriverDefinition;
import java.io.IOException;
import java.io.InputStream;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBigDecimal;
import org.jruby.RubyClass;
import org.jruby.RubyFloat;
import org.jruby.RubyModule;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.RubyObjectAdapter;
import org.jruby.RubyProc;
import org.jruby.RubyString;
import org.jruby.RubyTime;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.marshal.UnmarshalStream;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;

/**
 * Reader Class
 *
 * @author alexbcoles
 */
@JRubyClass(name = "Reader")
public class Reader extends RubyObject {

    public final static String RUBY_CLASS_NAME = "Reader";
    private static RubyObjectAdapter api;
    private static DriverDefinition driver;
    private static String moduleName;
    private static String errorName;

    private final static ObjectAllocator READER_ALLOCATOR = new ObjectAllocator() {

        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Reader instance = new Reader(runtime, klass);
            return instance;
        }
    };

    public static RubyClass createReaderClass(final Ruby runtime,
            final String moduleName, final String errorName,
            final DriverDefinition driverDefinition) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyModule driverModule = (RubyModule) doModule.getConstant(moduleName);
        RubyClass readerClass = driverModule.defineClassUnder(RUBY_CLASS_NAME,
                superClass, READER_ALLOCATOR);
        readerClass.defineAnnotatedMethods(Reader.class);
        Reader.api = JavaEmbedUtils.newObjectAdapter();
        Reader.driver = driverDefinition;
        Reader.moduleName = moduleName;
        Reader.errorName = errorName;
        return readerClass;
    }

    private Reader(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }
    // -------------------------------------------------- DATAOBJECTS PUBLIC API

    // default initialize
    @JRubyMethod
    public static IRubyObject close(IRubyObject recv) {
        Ruby runtime = recv.getRuntime();
        IRubyObject reader = api.getInstanceVariable(recv, "@reader");

        if (!(reader == null || reader.isNil())) {

            ResultSet rs = (ResultSet) reader.dataGetStruct();
            try {
                Statement st = rs.getStatement();
                rs.close();
                rs = null;
                st.close();
                st = null;
            } catch (SQLException ex) {
                Logger.getLogger(Reader.class.getName()).log(Level.SEVERE, null, ex);
            } finally {
                reader = api.setInstanceVariable(recv, "@reader", runtime.getNil());
            }

            return runtime.getTrue();
        } else {
            return runtime.getFalse();
        }
    }

    /**
     * Moves the cursor forward.
     *
     * @param recv
     * @return
     */
    @JRubyMethod(name = "next!")
    public static IRubyObject next(IRubyObject recv) throws SQLException {
        Ruby runtime = recv.getRuntime();
        IRubyObject reader = api.getInstanceVariable(recv, "@reader");
        ResultSet rs = (ResultSet) reader.dataGetStruct();

        if (rs == null) {
            return runtime.getFalse();
        }

        IRubyObject field_types = api.getInstanceVariable(recv, "@types");
        IRubyObject field_count = api.getInstanceVariable(recv, "@field_count");
        RubyArray row = runtime.newArray();
        IRubyObject value;
        int fieldTypesCount = field_types.convertToArray().getLength();

        boolean hasNext = rs.next();
        api.setInstanceVariable(recv, "@state", runtime.newBoolean(hasNext));

        if (!hasNext) {
            return runtime.getNil();
        }

        for (int i = 0; i < RubyNumeric.fix2int(field_count.convertToInteger()); i++) {
            int col = i + 1;
            RubyType type;

            if (fieldTypesCount > 0) {
                // use the specified type
                String typeName = field_types.convertToArray().get(i).toString();
                type = RubyType.getRubyType(typeName.toUpperCase());
            } else {
                // infer the type

                // assume the mapping from jdbc type to ruby type to be complete
                type = DataObjectsUtils.jdbcTypeToRubyType(rs.getMetaData().getColumnType(col),
                        rs.getMetaData().getScale(col));
            }

            // -- debugging what's coming out
            //System.out.println("Column Name: " + rs.getMetaData().getColumnName(col));
            //System.out.println("JDBC TypeName " + rs.getMetaData().getColumnTypeName(col));
            //System.out.println("JDBC Metadata scale " + rs.getMetaData().getScale(col));
            //System.out.println("Ruby Type " + type);
            // System.out.println(""); //for prettier output

            value = get_typecast_rs_value(runtime, rs, col, type);
            row.push_m(new IRubyObject[]{value});
        }

        api.setInstanceVariable(recv, "@values", row);
        return runtime.getTrue();
    }

    @JRubyMethod
    public static IRubyObject values(IRubyObject recv) {
        Ruby runtime = recv.getRuntime();
        IRubyObject state = api.getInstanceVariable(recv, "@state");

        if (state == null || state.isNil() || !state.isTrue()) {
            throw DataObjectsUtils.newDriverError(runtime, errorName, "Reader is not initialized");
        }
        IRubyObject values = api.getInstanceVariable(recv, "@values");
        return (values != null) ? values : runtime.getNil();
    }

    @JRubyMethod
    public static IRubyObject fields(IRubyObject recv) {
        return api.getInstanceVariable(recv, "@fields");
    }

    @JRubyMethod
    public static IRubyObject row_count(IRubyObject recv) {
        return api.getInstanceVariable(recv, "@row_count");
    }

    @JRubyMethod
    public static IRubyObject field_count(IRubyObject recv) {
        return api.getInstanceVariable(recv, "@field_count");
    }

    // -------------------------------------------------- PRIVATE HELPER METHODS

    /**
     *
     * @param rs
     * @param type
     * @return
     */
    private static IRubyObject get_typecast_rs_value(Ruby runtime, ResultSet rs,
            int col, RubyType type) throws SQLException {
        switch (type) {
            case CLASS:
                return runtime.getClass(rs.getString(col));
            case OBJECT:
                InputStream strm = rs.getAsciiStream(col);
                IRubyObject obj = runtime.getNil();
                try {
                    UnmarshalStream ums = new UnmarshalStream(runtime, strm, RubyProc.NEVER);
                    obj = ums.unmarshalObject();
                } catch (IOException ioe) {
                    // TODO: log this
                }
                return obj;
            case FIXNUM:
            case BIGNUM:
            case INTEGER:
                long lng = rs.getLong(col);
                return RubyNumeric.int2fix(runtime, lng);
            case BIG_DECIMAL:
                return new RubyBigDecimal(runtime, rs.getBigDecimal(col));
            case FLOAT:
                return new RubyFloat(runtime, rs.getDouble(col));
            case TRUE_CLASS:
                boolean bool = rs.getBoolean(col);
                return runtime.newBoolean(bool);
            case DATE:
                java.sql.Date dt = rs.getDate(col);
                if (dt == null || rs.wasNull()) {
                    return runtime.getNil();
                }
                // produces  RubyDate
                return DataObjectsUtils.prepareRubyDateFromSqlDate(runtime, dt);
                // produces RubyTime
                // return DataObjectsUtils.parse_date(runtime, dt);
            case DATE_TIME:
                java.sql.Timestamp ts = null;
                // DateTimes with all-zero components throw a SQLException with
                // SQLState S1009 in MySQL Connector/J 3.1+
                // See http://dev.mysql.com/doc/refman/5.0/en/connector-j-installing-upgrading.html
                try {
                    ts = rs.getTimestamp(col);
                } catch (SQLException sqle) {
                }
                if (ts == null || rs.wasNull()) {
                    return runtime.getNil();
                }
                // produces RubyDateTime
                return DataObjectsUtils.prepareRubyDateTimeFromSqlTimestamp(runtime,ts);
                // produces RubyTime
                // return DataObjectsUtils.parse_date_time(runtime, ts);

            case TIME:
                java.sql.Time tm = rs.getTime(col);
                if (tm == null || rs.wasNull()) {
                    return runtime.getNil();
                }
                // produces RubyString
                return  DataObjectsUtils.prepareRubyTimeFromSqlTime(runtime, tm);
                // produces RubyTime
                // return DataObjectsUtils.parse_time(runtime, tm);
            case STRING:
            default:
                String str = rs.getString(col);
                if (str == null || rs.wasNull()) {
                    return runtime.getNil();
                }
                RubyString return_str = RubyString.newUnicodeString(runtime, str);
                return_str.setTaint(true);
                return return_str;
        }
    }
}
