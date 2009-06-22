import java.sql.Timestamp;
import java.util.GregorianCalendar;
import java.util.TimeZone;

import org.joda.time.DateTime;
import org.joda.time.DateTimeZone;


public class TimeTest {
    @SuppressWarnings("deprecation")
    static public void main(String[] args) throws Exception {
        java.util.Date date = new java.util.Date();
        DateTime dateTime = new DateTime(date);//, DateTimeZone.getDefault()); 
        GregorianCalendar cal = new GregorianCalendar();
        cal.setTime(date);
        cal.setTimeZone(TimeZone.getTimeZone("UTC")); 
        // XXX works only if driver suports Calendars in PS
        java.sql.Timestamp ts;

        // IF clause
        ts = new java.sql.Timestamp(cal.getTime().getTime());
        ts.setNanos(cal.get(GregorianCalendar.MILLISECOND) * 1000000);
        System.out.println(ts + ": " + ts.getTime());
        System.out.println(cal);

        System.out.println(dateTime.toString("yyyy-MM-dd HH:mm:ss.SSS") + ": " + dateTime.getMillis());
        System.out.println(dateTime.toGregorianCalendar());
        GregorianCalendar gcal = dateTime.toGregorianCalendar();
        gcal.setTimeZone(TimeZone.getTimeZone("UTC")); 
        System.out.println(gcal.equals(cal));
        
        // ELSE clause
        dateTime = new DateTime(date);
                ts = new Timestamp(cal.get(GregorianCalendar.YEAR) - 1900, cal
                .get(GregorianCalendar.MONTH), cal
                .get(GregorianCalendar.DAY_OF_MONTH), cal
                .get(GregorianCalendar.HOUR_OF_DAY), cal
                .get(GregorianCalendar.MINUTE), cal
                .get(GregorianCalendar.SECOND), cal
                .get(GregorianCalendar.MILLISECOND) * 1000000);
        System.out.println(ts + ": " + ts.getTime());   
        System.out.println(cal);    
        dateTime = dateTime.withZone(DateTimeZone.UTC);
        System.out.println(dateTime.toString("yyyy-MM-dd HH:mm:ss.SSS") + ": " + dateTime.getMillis());
        System.out.println(dateTime.toGregorianCalendar());
        System.out.println(dateTime.toGregorianCalendar().equals(cal));

    }
}
