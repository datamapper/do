package do_jdbc;

import java.sql.DriverManager;
import java.sql.SQLException;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyObjectAdapter;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import static do_jdbc.DataObjects.DATA_OBJECTS_MODULE_NAME;

/**
 * Command Class
 * 
 * @author alexbcoles
 */
public class Command extends RubyObject {
    
    private static RubyObjectAdapter rubyApi;
    public final static String RUBY_CLASS_NAME = "Command";

    private final static ObjectAllocator COMMAND_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Command instance = new Command(runtime, klass);
            return instance;
        }
    };
    
    public static RubyClass createCommandClass(Ruby runtime, RubyModule jdbcModule) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyModule quotingModule = (RubyModule) doModule.getConstant("Quoting");
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyClass commandClass = runtime.defineClassUnder("Command",
                superClass, COMMAND_ALLOCATOR, jdbcModule);
        
        commandClass.includeModule(quotingModule);
        commandClass.defineAnnotatedMethods(Command.class);
        rubyApi = JavaEmbedUtils.newObjectAdapter();
        return commandClass;
    }
    
    private Command(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }
    
    // inherit initialize
    
    @JRubyMethod
    public static IRubyObject execute_non_query(IRubyObject recv) {
        Ruby runtime = recv.getRuntime();
        
        //sql = @connection.jdbc_connection.create_statement
	//return nil if (updcount = sql.execute_update(@text)) < 0
	//key = "TODO"
	//Result.new(self, updcount, key)
        
        return Result.createResultClass(runtime, runtime.getOrCreateModule("DataMapper::Jdbc"));
    }

    @JRubyMethod
    public static IRubyObject execute_reader(IRubyObject recv) throws SQLException {
        Ruby runtime = recv.getRuntime();
        
        String text = rubyApi.getInstanceVariable(recv, "@text").toString();
        java.sql.Connection conn = DriverManager.getConnection("URL", "username", "password");
        java.sql.Statement sql = conn.createStatement();
        
        sql.executeQuery(text);
        //Reader.new(sql.execute_query(@text), @types)

        // key = "TODO"
	// Result.new(self, updcount, key)
        // return runtime.getNil();
        
        // escape all parameters given and pass them to query
	
        // execute the query
	
        // if no response return nil
        
        // save the field count
	
        // instantiate a new reader
        
        // pass the response to the reader
	
        // mark the reader as opened
	
        // save the field_count in reader
	
        // get the field types
	
        // if no types passed, guess the types
	
        // for each field
	//   save its name
	//   guess the type if no types passed
	
        // set the reader @field_names and @types (guessed or otherwise)
	
        // yield the reader if a block is given, then close it
	
        // return the reader
	        
        return recv.getRuntime().getFalse();
    }

    @JRubyMethod
    public static IRubyObject quote_string(IRubyObject recv) {
        return recv.getRuntime().getFalse();
    }

    @JRubyMethod(required = 1)
    public static IRubyObject set_types(IRubyObject recv) {
        IRubyObject types = rubyApi.setInstanceVariable(recv, "@types", recv);
        return types;
    }
    
}
