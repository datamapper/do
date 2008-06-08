package data_objects;

import data_objects.drivers.DriverDefinition;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyObjectAdapter;
import org.jruby.anno.JRubyClass;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;

/**
 * Result Class
 *
 * @author alexbcoles
 */
@JRubyClass(name = "Result")
public class Result extends RubyObject {

    public final static String RUBY_CLASS_NAME = "Result";
    private static RubyObjectAdapter api;
    private static DriverDefinition driver;
    private static String moduleName;
    private static String errorName;

    private final static ObjectAllocator RESULT_ALLOCATOR = new ObjectAllocator() {

        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Result instance = new Result(runtime, klass);
            return instance;
        }
    };

    public static RubyClass createResultClass(final Ruby runtime,
            final String moduleName, final String errorName,
            final DriverDefinition driverDefinition) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyModule driverModule = (RubyModule) doModule.getConstant(moduleName);
        RubyClass resultClass = driverModule.defineClassUnder(RUBY_CLASS_NAME,
                superClass, RESULT_ALLOCATOR);
        Result.api = JavaEmbedUtils.newObjectAdapter();
        Result.driver = driverDefinition;
        Result.moduleName = moduleName;
        Result.errorName = errorName;
        resultClass.defineAnnotatedMethods(Result.class);
        return resultClass;
    }

    private Result(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }    // inherit initialize
}
