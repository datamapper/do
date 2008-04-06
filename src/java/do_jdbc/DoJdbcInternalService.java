package do_jdbc;

import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObjectAdapter;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.BasicLibraryService;

public class DoJdbcInternalService implements BasicLibraryService {
    private static RubyObjectAdapter rubyApi;
    private static Ruby runtime;
    
    public static String rb_mKernel = "";
    
    // Get references classes needed for Date/Time parsing 
    public static IRubyObject rb_cDate = CONST_GET(rb_mKernel, "Date");
    public static IRubyObject rb_cDateTime = CONST_GET(rb_mKernel, "DateTime");
    public static IRubyObject rb_cTime = CONST_GET(rb_mKernel, "Time");
    public static IRubyObject rb_cRational = CONST_GET(rb_mKernel, "Rational");

    public static RubyModule doModule = Ruby.getCurrentInstance().getModule("DataObjects");
    public static RubyModule jdbcModule = Ruby.getCurrentInstance()
            .defineModuleUnder("JDBC", doModule);
    
    // Get references to the DataObjects module and its classes
    public static RubyClass cDO_Quoting = (RubyClass) CONST_GET(doModule, "Quoting");
    public static RubyClass cDO_Connection = (RubyClass) CONST_GET(doModule, "Connection");
    public static RubyClass cDO_Command = (RubyClass) CONST_GET(doModule, "Command");
    public static RubyClass cDO_Result = (RubyClass) CONST_GET(doModule, "Result");
    public static RubyClass DO_Reader = (RubyClass) CONST_GET(doModule, "Reader");
    
    private RubyClass connection;
    private RubyClass command;
    private RubyClass result;
    private RubyClass reader;
    private RubyClass transaction;
    
    public static IRubyObject CONST_GET(Object scope, String constant) {
        return Ruby.getCurrentInstance().getClass(constant);
    }
    
    /**
     * 
     * @param runtime
     * @param name
     * @param superClass
     * @param allocator
     * @return
     */
    public static RubyClass createDoJdbcClass(Ruby runtime, String name, 
            RubyClass superClass, ObjectAllocator allocator) {
        return runtime.defineClassUnder(name, superClass, allocator, doModule);
    }
    
    public boolean basicLoad(final Ruby runtime) throws IOException {
        
        //rb_require("rubygems");
        //rb_require("bigdecimal");
        //rb_require("date");
        //rb_require("cgi");
        
        // Initialize the Jdbc Module and create its classes.
        connection = Connection.createConnectionClass(runtime);
        command = Command.createCommandClass(runtime);
        result = Result.createResultClass(runtime);
        reader = Reader.createReaderClass(runtime);
        transaction = Transaction.createTransactionClass(runtime);
        
        System.out.println("FISHCAKES");
        
        return true;
    }
    
}