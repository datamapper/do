package do_jdbc;

import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyObjectAdapter;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.Block;
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

    public final static String RUBY_CLASS_NAME = "Command";
    private static RubyObjectAdapter rubyApi;

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

        IRubyObject connection = rubyApi.getInstanceVariable(recv, "@connection");
        //System.out.println("FOR THE INSTANT!: " + connection.getVariableNameList());
            // should be @uri, @connection and one other thing

        IRubyObject wrappedJdbcConnection = rubyApi.getInstanceVariable(connection, "@connection");
        //java.sql.Connection conn2 = DoJdbcUtils.getConnection(wrappedJdbcConnection);

        System.out.println("--" + (wrappedJdbcConnection ==  null));
        System.out.println("--" + (wrappedJdbcConnection.getClass().getCanonicalName()));
        System.out.println("--" + wrappedJdbcConnection.dataGetStruct());
        Object conn = (Object) wrappedJdbcConnection.dataGetStruct();
        System.out.println("--" + conn.toString());
        System.out.println("--" + conn.getClass().getCanonicalName());

        String text = ""; // TODO: build query from args

        java.sql.Connection fish = (java.sql.Connection) wrappedJdbcConnection.dataGetStruct();
        int affectedCount = 0;           // rows affected
        Statement sqlStatement = null;
        java.sql.ResultSet keys = null;
        try {
            sqlStatement = fish.createStatement();
            //sqlStatement.setMaxRows();
            affectedCount = sqlStatement.executeUpdate(text, Statement.RETURN_GENERATED_KEYS);
            keys = sqlStatement.getGeneratedKeys();
            //
            sqlStatement.close();
            sqlStatement = null;
        } catch (SQLException sqle) {
            // do something with the SQLException
            // TODO: throw a Ruby Error
        } finally {
            if (sqlStatement != null) {
                try {
                    sqlStatement.close();
                } catch (SQLException sqle2) {
                }
            }
        }

        // return nil if no updates are made
        if (affectedCount <= 0) {
            return runtime.getNil();
        }

        IRubyObject affected_rows = runtime.newFixnum(affectedCount);
        IRubyObject insertKey = null; // TODO: fix this

        RubyClass result = Result.createResultClass(runtime, jdbcModule);
        IRubyObject[] args = new IRubyObject[] { recv, affected_rows, insertKey };
        result.initialize(args, Block.NULL_BLOCK);
        return result;
    }

    @JRubyMethod
    public static IRubyObject execute_reader(IRubyObject recv) {
        Ruby runtime = recv.getRuntime();

        RubyModule jdbcModule = null; // FIXME

        IRubyObject conn = rubyApi.getInstanceVariable(recv, "@connection");
        String text = rubyApi.getInstanceVariable(recv, "@text").toString();
        java.sql.Connection conn2 = (java.sql.Connection) conn.dataGetStruct();

        IRubyObject wrappedJdbcConnection = rubyApi.getInstanceVariable(conn, "@connection");
        //java.sql.Connection conn2 = DoJdbcUtils.getConnection(wrappedJdbcConnection);

	boolean inferTypes = false;

        RubyClass reader;
        // escape all parameters given and pass them to query
        String query = build_query_from_args(recv);

        java.sql.Connection fish = (java.sql.Connection) wrappedJdbcConnection.dataGetStruct();
        int colCount = 0;
        int rowCount = 0;
        Statement sqlStatement = null;
        ResultSet resultSet = null;
        ResultSetMetaData rsMetaData = null;

        // execute the query

        try {
            sqlStatement = fish.createStatement();
            //sqlStatement.setMaxRows();
            resultSet = sqlStatement.executeQuery(text);

            while (resultSet.next()) {
                rowCount++;
                
                if (rowCount == 1) {
                    rsMetaData = resultSet.getMetaData();
                    colCount = rsMetaData.getColumnCount();
                }
                
            // handle each result
            }

            // TODO: if no response return nil

            resultSet.close();
            resultSet = null;
            sqlStatement.close();
            sqlStatement = null;
        } catch (SQLException sqlex) {
            // do something with the SQLException
            // TODO: throw a Ruby Error
        } finally {
            if (resultSet != null) {
                try {
                    resultSet.close();
                } catch (SQLException rssqlex) {
                }
            }
            if (sqlStatement != null) {
                try {
                    sqlStatement.close();
                } catch (SQLException stsqlex) {
                }
            }
        }

        // save the field count
        // TODO
        
        // instantiate a new reader
        reader = Reader.createReaderClass(runtime, jdbcModule);
        reader.initialize();
        reader.setInstanceVariable("@position", runtime.newFixnum(0));

        // pass the response to the reader
        reader.setInstanceVariable("@reader", null);          // TODO: Data_Wrap_Struct(rb_cObject, 0, 0, response)

        // mark the reader as opened
        // TODO
        
        // save the field_count in reader
        reader.setInstanceVariable("@field_count", runtime.newFixnum(colCount));
        reader.setInstanceVariable("@row_count",   runtime.newFixnum(rowCount));
        
        // get the field types
        RubyArray fieldNames = runtime.newArray();
        IRubyObject field_types = rubyApi.getInstanceVariable(recv , "@field_types");
        
        // if no types passed, guess the types
        if (field_types.isNil() || field_types.convertToArray().length().getLongValue() == 0)
        {
            field_types = runtime.newArray();
            inferTypes = true;
        }

        // for each field
        // USE RESULTSETMETADATA FOR THIS
        //for (int i = 0; i < colCount; i++) {
            //   save its name
         //   fieldNames.push_m(NULL_ARRAY); // rb_ary_push(field_names, rb_str_new2(PQfname(response, i)));
            //   guess the type if no types passed
           // if (inferTypes) {
           //     field_types.push_m(getRubyType()); // (PQftype(response, i))
            //}
        //}
            
        // set the reader @field_names and @types (guessed or otherwise)
        reader.setInstanceVariable("@fields", fieldNames);
        reader.setInstanceVariable("@field_types", field_types);

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

   private static String build_query_from_args(IRubyObject recv) {
        throw new UnsupportedOperationException("Not yet implemented");
    }

}
