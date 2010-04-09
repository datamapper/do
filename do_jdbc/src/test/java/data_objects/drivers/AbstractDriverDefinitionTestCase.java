package data_objects.drivers;

import java.net.URI;
import java.util.LinkedList;
import java.util.Map;

import junit.framework.TestCase;

import org.jruby.Ruby;
import org.jruby.RubyHash;
import org.jruby.RubyObjectAdapter;
import org.jruby.RubyRuntimeAdapter;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.builtin.IRubyObject;

public class AbstractDriverDefinitionTestCase extends TestCase {

    private static class MyAbstractDriverDefinition extends AbstractDriverDefinition {
        MyAbstractDriverDefinition() {
            super("sqlite3", "sqlite", "Sqlite3", "org.sqlite.JDBC");
        }

        public boolean supportsJdbcGeneratedKeys() {
            return false;
        }

        public boolean supportsJdbcScrollableResultSets() {
            return false;
        }
    }

    protected IRubyObject getConnectionUri(String uri) {
        final Ruby runtime = JavaEmbedUtils.initialize(new LinkedList());
        final RubyRuntimeAdapter evaler = JavaEmbedUtils.newRuntimeAdapter();
        final IRubyObject result = evaler.eval(runtime, "require 'rubygems'\nrequire 'data_objects'\nDataObjects::URI.parse('" + uri + "')");
        assertEquals("DataObjects::URI", result.getType().getName());

        return result;
    }

    protected Map<Object, Object> getQueryParameter(IRubyObject connection_uri) {
        final RubyObjectAdapter api = JavaEmbedUtils.newObjectAdapter();
        final IRubyObject query_values = api.callMethod(connection_uri, "query");

	if (query_values.isNil())
            return null;
        else
            return query_values.convertToHash();
    }

    public void testParseConnectionURI() throws Exception {
        final String uri = "sqlite3://path/to/file?param1=value1&param2=value2";
        final AbstractDriverDefinition driver = new MyAbstractDriverDefinition();

        final IRubyObject connection_uri = getConnectionUri(uri);
        final IRubyObject result_connection_uri = getConnectionUri(driver.parseConnectionURI(connection_uri).toString());

        assertEquals(getQueryParameter(connection_uri), getQueryParameter(result_connection_uri));
    }
}
