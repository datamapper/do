

import do_jdbc.Command;
import do_jdbc.Connection;
import do_jdbc.Reader;
import do_jdbc.Result;
import do_jdbc.Transaction;
import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObjectAdapter;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.BasicLibraryService;

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
        
        doModule = runtime.getModule("DataObjects");

        //rb_require("rubygems");
        //rb_require("bigdecimal");
        //rb_require("date");
        //rb_require("cgi");
        
        RubyClass connectionSuperClass = doModule.getClass(Connection.RUBY_CLASS_NAME);
        RubyClass commandSuperClass = doModule.getClass(Command.RUBY_CLASS_NAME);
        RubyClass resultSuperClass = doModule.getClass(Result.RUBY_CLASS_NAME);
        RubyClass readerSuperClass = doModule.getClass(Reader.RUBY_CLASS_NAME);
        RubyClass transactionSuperClass = doModule.getClass(Reader.RUBY_CLASS_NAME);
        
        // Initialize the Jdbc Module and create its classes.
        //jdbcModule = (RubyModule) doModule.getConstant("JDBC");
        jdbcModule = doModule.defineModuleUnder("JDBC");
        
        connection = Connection.createConnectionClass(jdbcModule, connectionSuperClass);
        //command = Command.createCommandClass(jdbcModule);
        result = Result.createResultClass(jdbcModule, resultSuperClass);
        //reader = Reader.createReaderClass(jdbcModule);
        //transaction = Transaction.createTransactionClass(jdbcModule);
        
        return true;
    }
    
}