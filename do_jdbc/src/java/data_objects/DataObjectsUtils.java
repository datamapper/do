package data_objects;

import java.sql.Date;
import java.sql.SQLException;
import java.sql.Time;
import java.sql.Timestamp;
import java.sql.Types;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;


import java.util.Calendar;
import java.util.GregorianCalendar;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyNumeric;
import org.jruby.RubyRational;
import org.jruby.RubyTime;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Additional Utilities for DataObjects JDBC Drivers
 *
 * @author alexbcoles
 */
public final class DataObjectsUtils {

    private static final DateFormat utilDateFormatter = new SimpleDateFormat("dd-MM-yyyy");
    private static final DateFormat sqlDateFormatter = new SimpleDateFormat("yyyy-MM-dd");
    private static final GregorianCalendar gregCalendar = new GregorianCalendar();

    /**
     * Create a driver Error
     *
     * @param runtime
     * @param errorName
     * @param message
     * @return
     */
    public static RaiseException newDriverError(Ruby runtime, String errorName,
            String message) {
        RubyClass driverError = runtime.getClass(errorName);
        return new RaiseException(runtime, driverError, message, true);
    }

    /**
     * Create a driver Error from a java.sql.SQLException
     *
     * @param runtime
     * @param errorName
     * @param exception
     * @return
     */
    public static RaiseException newDriverError(Ruby runtime, String errorName,
            SQLException exception) {
        RubyClass driverError = runtime.getClass(errorName);
        int code = exception.getErrorCode();
        // TODO: parse vendor exception codes
        String message = exception.getLocalizedMessage();
        return new RaiseException(runtime, driverError, message, true);
    }

    // STOLEN FROM AR-JDBC
    static java.sql.Connection getConnection(IRubyObject recv) {
        java.sql.Connection conn = (java.sql.Connection) recv.dataGetStruct();
        return conn;
    }

    /**
     * Converts a JDBC Type to a Ruby Type
     *
     * @param type
     * @param scale
     * @return
     */
    public static RubyType jdbcTypeToRubyType(int type, int scale) {
        RubyType primitiveType;
        switch (type) {
            case Types.INTEGER:
            case Types.SMALLINT:
            case Types.TINYINT:
                primitiveType = RubyType.FIXNUM;
                break;
            case Types.BIGINT:
                primitiveType = RubyType.BIGNUM;
                break;
            case Types.BIT:
            case Types.BOOLEAN:
                primitiveType = RubyType.TRUE_CLASS;
                break;
            case Types.CHAR:
            case Types.VARCHAR:
                primitiveType = RubyType.STRING;
                break;
            case Types.DATE:
                primitiveType = RubyType.DATE;
                break;
            case Types.TIMESTAMP:
                primitiveType = RubyType.DATE_TIME;
                break;
            case Types.TIME:
                primitiveType = RubyType.TIME;
                break;
            case Types.DECIMAL:
            case Types.NUMERIC:
                primitiveType = RubyType.BIG_DECIMAL;
                break;
            case Types.FLOAT:
            case Types.DOUBLE:
                primitiveType = RubyType.FLOAT;
                break;
            default:
                primitiveType = RubyType.STRING;
        }
        // No casting rule for type #{meta_data.column_type(i)} (#{meta_data.column_name(i)}). Please report this."
        return primitiveType;
    }

    public static java.sql.Date utilDateToSqlDate(java.util.Date uDate) throws ParseException {
        return java.sql.Date.valueOf(sqlDateFormatter.format(uDate));
    }

    public static java.util.Date sqlDateToutilDate(java.sql.Date sDate) throws ParseException {
        return (java.util.Date) utilDateFormatter.parse(utilDateFormatter.format(sDate));
    }

    public static IRubyObject parse_date(Ruby runtime, Date dt) {
        RubyTime time = RubyTime.newTime(runtime, dt.getTime());
        time.extend(new IRubyObject[] {runtime.getModule("DateFormatter")});
        return time;
    }

    public static IRubyObject parse_date_time(Ruby runtime, Timestamp ts) {
        RubyTime time = RubyTime.newTime(runtime, ts.getTime());
        time.extend(new IRubyObject[] {runtime.getModule("DatetimeFormatter")});
        return time;
    }

    public static IRubyObject parse_time(Ruby runtime, Time tm) {
        RubyTime time = RubyTime.newTime(runtime, tm.getTime());
        time.extend(new IRubyObject[] {runtime.getModule("TimeFormatter")});
        return (time.getUSec() != 0) ? time : runtime.getNil();
    }

    public static IRubyObject prepareRubyDateFromSqlDate(Ruby runtime,Date date){
       gregCalendar.setTime(date);
       int month = gregCalendar.get(Calendar.MONTH);
       month++; // In Calendar January == 0, etc...
       RubyClass klazz = runtime.fastGetClass("Date");
       return klazz.callMethod(
                 runtime.getCurrentContext() ,"civil",
                 new IRubyObject []{ runtime.newFixnum(gregCalendar.get(Calendar.YEAR)),
                 runtime.newFixnum(month),
                 runtime.newFixnum(gregCalendar.get(Calendar.DAY_OF_MONTH))});
    }

    public static IRubyObject prepareRubyDateTimeFromSqlTimestamp(Ruby runtime,Timestamp stamp){
       gregCalendar.setTime(stamp);
       int month = gregCalendar.get(Calendar.MONTH);
       month++; // In Calendar January == 0, etc...

       int zoneOffset = gregCalendar.get(Calendar.ZONE_OFFSET)/3600000;
       RubyClass klazz = runtime.fastGetClass("DateTime");

       IRubyObject rbOffset = runtime.fastGetClass("Rational")
                .callMethod(runtime.getCurrentContext(), "new",new IRubyObject[]{
            runtime.newFixnum(zoneOffset),runtime.newFixnum(24)
        });

       return klazz.callMethod(runtime.getCurrentContext() , "civil",
                 new IRubyObject []{runtime.newFixnum(gregCalendar.get(Calendar.YEAR)),
                 runtime.newFixnum(month),
                 runtime.newFixnum(gregCalendar.get(Calendar.DAY_OF_MONTH)),
                 runtime.newFixnum(gregCalendar.get(Calendar.HOUR_OF_DAY)),
                 runtime.newFixnum(gregCalendar.get(Calendar.MINUTE)),
                 runtime.newFixnum(gregCalendar.get(Calendar.SECOND)),
                 rbOffset});
    }

     public static IRubyObject prepareRubyTimeFromSqlTime(Ruby runtime,Time time){
       RubyTime rbTime = RubyTime.newTime(runtime, time.getTime());
       rbTime.extend(new IRubyObject[] {runtime.getModule("TimeFormatter")});
       if(rbTime.getJavaDate().getTime() == 0){
            return runtime.getNil();
       }else{
            SimpleDateFormat sdf = new SimpleDateFormat("HH-mm-ss"); // TODO proper format?
            return runtime.newString(sdf.format(rbTime.getJavaDate()));
       }
     }

    // private constructor
    private DataObjectsUtils() {
    }
}
