package do_jdbc;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Additional Utilities for DataObjects JDBC Drivers
 * 
 * @author alexbcoles
 */
public class DoJdbcUtils {
    
    public static RaiseException newJdbcError(Ruby runtime, String message) {
        RubyClass jdbcError = runtime.getClass("JdbcError");
        return new RaiseException(runtime, jdbcError, message, true);
    }
    
    // STOLEN FROM AR-JDBC
    static java.sql.Connection getConnection(IRubyObject recv) {
        java.sql.Connection conn = (java.sql.Connection) recv.dataGetStruct();
        return conn;
    }

    private static IRubyObject java_types_to_ruby_types(Ruby runtime, int row, 
            int type, int scale, ResultSet rs) throws SQLException {
       //try {
            String dmType;
        
            switch(type) {
                case Types.INTEGER:
                case Types.SMALLINT:
                case Types.TINYINT:
                    dmType = "Fixnum";
                case Types.BIGINT:
                    dmType = "Bignum";
                case Types.BIT:
                case Types.BOOLEAN:
                    dmType = "TrueClass";
                case Types.CHAR:
                case Types.VARCHAR:
                    dmType = "String";
                case Types.DATE:
                    dmType = "Date";
                case Types.TIMESTAMP:
                    dmType = "DateTime";
                case Types.TIME:
                    dmType = "Time";
                case Types.DECIMAL:
                case Types.NUMERIC:
                    dmType = "BigDecimal";
                case Types.FLOAT:
                case Types.DOUBLE:
                    dmType = "Float";
                case Types.OTHER:
                    dmType = "String";
                    
                
            } 
                // No casting rule for type #{meta_data.column_type(i)} (#{meta_data.column_name(i)}). Please report this."
        
                return null;
        } //catch(IOException ioe) {
          //  throw (SQLException) new SQLException(ioe.getMessage()).initCause(ioe);
        //}
    //}
    
    private static IRubyObject type_cast_value(int index, Object value) {
        //Ruby runtime = recv.getRuntime(); 

//        
//        	if String == @types[index]
//	  value.to_s
//        elsif [Fixnum, Bignum].include?(@types[index])
//	  value.to_i
//        elsif BigDecimal == @types[index]
//	  BigDecimal.new(value.to_string)
//        elsif Float == @types[index]
//	  value.to_f
//	elsif [TrueClass, FalseClass].include?(@types[index])
//	  value
//        elsif Date == @types[index]
//	  Date.parse(value.to_string)
//        elsif DateTime == @types[index]
//	  DateTime.parse(value.to_string)
	//else
	//  raise "Oops! Forgot to handle #{@types[index]} (#{value})"
	//end
        
        return null;
    }
    
}
