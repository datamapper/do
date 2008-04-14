

import do_jdbc.Command;
import do_jdbc.Connection;
import do_jdbc.Reader;
import do_jdbc.Result;
import do_jdbc.Transaction;
import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.runtime.load.BasicLibraryService;

import static do_jdbc.DataObjects.DATA_OBJECTS_MODULE_NAME;
import static do_jdbc.DataObjects.JDBC_MODULE_NAME;

/**
 * 
 * thanks to Ola Bini's 
 * http://ola-bini.blogspot.com/2006/10/jruby-tutorial-4-writing-java.html
 * 
 * @author alexbcoles
 */
public class DoJdbcInternalService implements BasicLibraryService {
    
//    public static String rb_mKernel = "";
//    
//    // Get references classes needed for Date/Time parsing 
//    public static IRubyObject rb_cDate = CONST_GET(rb_mKernel, "Date");
//    public static IRubyObject rb_cDateTime = CONST_GET(rb_mKernel, "DateTime");
//    public static IRubyObject rb_cTime = CONST_GET(rb_mKernel, "Time");
//    public static IRubyObject rb_cRational = CONST_GET(rb_mKernel, "Rational");
//
    public static RubyModule doModule;
    public static RubyModule jdbcModule;
    
//    // Get references to the DataObjects module and its classes
//    public static RubyClass cDO_Quoting = (RubyClass) CONST_GET(doModule, "Quoting");
//    public static RubyClass cDO_Connection = (RubyClass) CONST_GET(doModule, "Connection");
//    public static RubyClass cDO_Command = (RubyClass) CONST_GET(doModule, "Command");
//    public static RubyClass cDO_Result = (RubyClass) CONST_GET(doModule, "Result");
//    public static RubyClass DO_Reader = (RubyClass) CONST_GET(doModule, "Reader");
//    
    private RubyClass connection;
    private RubyClass command;
    private RubyClass result;
    private RubyClass reader;
    private RubyClass transaction;
//    
//    public static IRubyObject CONST_GET(Object scope, String constant) {
//        return Ruby.getCurrentInstance().getClass(constant);
//    }
    
    public boolean basicLoad(Ruby runtime) throws IOException {     
        
        doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);

        //rb_require("rubygems");
        //rb_require("bigdecimal");
        //rb_require("date");
        //rb_require("cgi");
        
        // Initialize the Jdbc Module and create its classes.
        //jdbcModule = (RubyModule) doModule.getConstant("JDBC");
        jdbcModule = doModule.defineModuleUnder(JDBC_MODULE_NAME);
        
        command = Command.createCommandClass(runtime, jdbcModule);
        connection = Connection.createConnectionClass(runtime, jdbcModule);
        result = Result.createResultClass(runtime, jdbcModule);
        reader = Reader.createReaderClass(runtime, jdbcModule);
        transaction = Transaction.createTransactionClass(runtime, jdbcModule);
        
        return true;
    }

}