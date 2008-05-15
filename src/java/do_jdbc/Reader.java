package do_jdbc;

import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyObjectAdapter;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import static do_jdbc.DataObjects.DATA_OBJECTS_MODULE_NAME;

/**
 * Reader Class
 * 
 * @author alexbcoles
 */
public class Reader extends RubyObject {
    
    private static RubyObjectAdapter rubyApi;
    public final static String RUBY_CLASS_NAME = "Reader";

    private final static ObjectAllocator READER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Reader instance = new Reader(runtime, klass);
            return instance;
        }
    };
    
    public static RubyClass createReaderClass(Ruby runtime, RubyModule jdbcModule) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyClass readerClass = jdbcModule.defineClassUnder(RUBY_CLASS_NAME, 
                superClass, READER_ALLOCATOR);
        readerClass.defineAnnotatedMethods(Reader.class);
        rubyApi = JavaEmbedUtils.newObjectAdapter();
        return readerClass;
    }
    
    private Reader(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }
    
    //@JRubyMethod(name = "initialize", required = 2) 
    //public static IRubyObject initialize(IRubyObject recv) {
    //    return recv;
    //}
    
    //
    // @result = result
    // @meta_data = result.meta_data
    // @types = types || java_types_to_ruby_types(@meta_data)
    //
    
    @JRubyMethod
    public static IRubyObject close(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }

    /**
     * Moves the cursor forward.
     * 
     * @param recv
     * @return
     */
    @JRubyMethod(name = "next!")
    public static IRubyObject next(IRubyObject recv) {
        // @in_row = (@result.next || nil)
        IRubyObject result_next = rubyApi.getInstanceVariable(recv, "@result.next");
        // recv.getRuntime().getNil();
        IRubyObject in_row = rubyApi.setInstanceVariable(recv, "@in_row", result_next);
        
        return in_row;
    }

    @JRubyMethod
    public static IRubyObject values(IRubyObject recv) {
       
        //raise "error" unless @in_row
       // new RaiseException(recv.getRuntime(), "error", "error");
        
        IRubyObject values = rubyApi.getInstanceVariable(recv, "@values");
        
//        
//
//	@values = (1 .. @meta_data.column_count).map do |i|
//	  type_cast_value(i - 1, @result.object(i))
//	end
        
        return recv.getRuntime().getFalse();
    }

    @JRubyMethod
    public static IRubyObject fields(IRubyObject recv) {
        Ruby runtime = recv.getRuntime();
        IRubyObject fields = rubyApi.getInstanceVariable(recv, "@fields");
        
//        	@fields ||= begin
//	  ccnt = @meta_data.column_count
//	  fields = []
//	  1.upto(ccnt) do |i|
//	    fields << @meta_data.column_name(i)
//	  end
//	  fields
//	end
        
        
        return recv.getRuntime().getFalse();
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
