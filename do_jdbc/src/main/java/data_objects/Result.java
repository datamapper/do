package data_objects;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import data_objects.drivers.DriverDefinition;

/**
 * Result Class
 *
 * @author alexbcoles
 */
@SuppressWarnings("serial")
@JRubyClass(name = "Result")
public class Result extends RubyObject {

    public final static String RUBY_CLASS_NAME = "Result";

    private final static ObjectAllocator RESULT_ALLOCATOR = new ObjectAllocator() {

        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            return new Result(runtime, klass);
        }
    };

    /**
     *
     * @param runtime
     * @param driver
     * @return
     */
    public static RubyClass createResultClass(final Ruby runtime, DriverDefinition driver){
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyModule driverModule = (RubyModule) doModule.getConstant(driver.getModuleName());
        RubyClass resultClass = driverModule.defineClassUnder(RUBY_CLASS_NAME,
                superClass, RESULT_ALLOCATOR);

        resultClass.defineAnnotatedMethods(Result.class);
        return resultClass;
    }

    /**
     *
     * @param runtime
     * @param klass
     */
    private Result(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }    // inherit initialize
}
