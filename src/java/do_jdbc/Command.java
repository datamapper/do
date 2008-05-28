package do_jdbc;

import java.sql.DriverManager;
import java.sql.SQLException;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyObjectAdapter;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import static do_jdbc.DataObjects.DATA_OBJECTS_MODULE_NAME;
import static do_jdbc.DataObjects.JDBC_MODULE_NAME;

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
        RubyModule jdbcModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME).defineModuleUnder(JDBC_MODULE_NAME);
        
        //sql = @connection.jdbc_connection.create_statement
	//return nil if (updcount = sql.execute_update(@text)) < 0
	//key = "TODO"
	//Result.new(self, updcount, key)
        
        return Result.createResultClass(runtime, jdbcModule);
    }

    @JRubyMethod
    public static IRubyObject execute_reader(IRubyObject recv) throws SQLException {
        Ruby runtime = recv.getRuntime();
        
        String text = rubyApi.getInstanceVariable(recv, "@text").toString();
        java.sql.Connection conn = DriverManager.getConnection("URL", "username", "password");
        java.sql.Statement sql = conn.createStatement();
        
        sql.executeQuery(text);
        
        
//       ALUE reader, query;
//	VALUE field_names, field_types;
//
        int i;
        int field_count;
//	int infer_types = 0;
//
//	PGconn *db = DATA_PTR(rb_iv_get(rb_iv_get(self, "@connection"), "@connection"));
//	PGresult *response;
//
//	query = build_query_from_args(self, argc, argv);
//	data_objects_debug(query);
//
//	response = PQexec(db, StringValuePtr(query));
//
//	if ( PQresultStatus(response) != PGRES_TUPLES_OK ) {
//		char *message = PQresultErrorMessage(response);
//		PQclear(response);
//		rb_raise(ePostgresError, message);
//	}
//
//	field_count = PQnfields(response);
//
//	reader = rb_funcall(cReader, ID_NEW, 0);
        
        RubyModule jdbcModule = null; // FIXME
        RubyClass reader = Reader.createReaderClass(runtime, jdbcModule);
        
//	rb_iv_set(reader, "@reader", Data_Wrap_Struct(rb_cObject, 0, 0, response));
//	rb_iv_set(reader, "@field_count", INT2NUM(field_count));
//	rb_iv_set(reader, "@row_count", INT2NUM(PQntuples(response)));
//
        RubyArray fieldNames = runtime.newArray();
//	field_types = rb_iv_get(self, "@field_types");
//
//	if ( field_types == Qnil || RARRAY(field_types)->len == 0 ) {
//		field_types = rb_ary_new();
//		infer_types = 1;
//	}
//
//	for ( i = 0; i < field_count; i++ ) {
//		rb_ary_push(field_names, rb_str_new2(PQfname(response, i)));
//		if ( infer_types == 1 ) {
//			rb_ary_push(field_types, infer_ruby_type(PQftype(response, i)));
//		}
//	}

        //reader.instance_variable_set(reader., 0);
//	rb_iv_set(reader, "@position", INT2NUM(0));
//	rb_iv_set(reader, "@fields", field_names);
//	rb_iv_set(reader, "@field_types", field_types);
//
//	return reader;
//        
        
        
        
        
        
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
        return reader;
    }

    @JRubyMethod
    public static IRubyObject quote_boolean(IRubyObject recv, IRubyObject value) {
        
        return recv.getRuntime().getFalse();
    }
    
    @JRubyMethod
    public static IRubyObject quote_string(IRubyObject recv, IRubyObject value) {
        
        // how do we handle quoted strings with JDBC?
        // ("\"" + include + "\"");
        
        return recv.getRuntime().getFalse();
    }

    @JRubyMethod(required = 1)
    public static IRubyObject set_types(IRubyObject recv, IRubyObject value) {
        IRubyObject types = rubyApi.setInstanceVariable(recv, "@types", value);
        return types;
    }
    
}
