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

    DORubyObject(Ruby arg0, RubyClass clazz) {
        super(arg0, clazz);
        this.driver = (DriverDefinition) JavaEmbedUtils.rubyToJava(clazz
                .getInstanceVariable("@__driver"));
        this.api = driver.getObjectAdapter();
    }

    static void setDriverDefinition(RubyClass clazz, Ruby runtime, DriverDefinition driver) {
        clazz.setInstanceVariable("@__driver", JavaEmbedUtils.javaToRuby(
                runtime, driver));
    }

}
