
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
    
    public static RubyModule doModule;
    public static RubyModule jdbcModule;
    
    private static RubyClass connection;
    private static RubyClass command;
    private static RubyClass result;
    private static RubyClass reader;
    private static RubyClass transaction;

    public boolean basicLoad(Ruby runtime) throws IOException {     
        
        doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);

        // Define the Jdbc Module and its classes.
        jdbcModule = doModule.defineModuleUnder(JDBC_MODULE_NAME);
        
        command = Command.createCommandClass(runtime, jdbcModule);
        connection = Connection.createConnectionClass(runtime, jdbcModule);
        result = Result.createResultClass(runtime, jdbcModule);
        reader = Reader.createReaderClass(runtime, jdbcModule);
        transaction = Transaction.createTransactionClass(runtime, jdbcModule);
        
        return true;
    }

}