package data_objects;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.RubyObjectAdapter;
import org.jruby.javasupport.JavaEmbedUtils;

import data_objects.drivers.DriverDefinition;

@SuppressWarnings("serial")
abstract public class DORubyObject extends RubyObject {

    final DriverDefinition driver;

    final RubyObjectAdapter api;

    /**
     *
     * @param runtime
     * @param clazz
     */
    DORubyObject(Ruby runtime, RubyClass clazz) {
        super(runtime, clazz);
        this.driver = (DriverDefinition) JavaEmbedUtils.rubyToJava(clazz
                .getInstanceVariable("@__driver"));
        this.api = driver.getObjectAdapter();
    }

    /**
     *
     * @param clazz
     * @param runtime
     * @param driver
     */
    static void setDriverDefinition(RubyClass clazz, Ruby runtime, DriverDefinition driver) {
        clazz.setInstanceVariable("@__driver", JavaEmbedUtils.javaToRuby(
                runtime, driver));
    }

}
