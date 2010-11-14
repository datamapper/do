package data_objects.drivers;

import java.net.URI;
import java.sql.PreparedStatement;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Map;

import junit.framework.TestCase;

import org.jmock.Mockery;
import org.jmock.Expectations;

import org.jruby.Ruby;
import org.jruby.RubyFixnum;
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

    private Mockery context;
    private Ruby runtime;

    public void setUp() {
        context = new Mockery();
        runtime = JavaEmbedUtils.initialize(new LinkedList());
    }

    protected IRubyObject getConnectionUri(String uri) {
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

        assertEquals(new HashMap(getQueryParameter(connection_uri)), new HashMap(getQueryParameter(result_connection_uri)));
    }

    public void testSetPreparedStatementParam() throws Exception {
        final PreparedStatement ps = context.mock(PreparedStatement.class);
        final Long num = Long.MAX_VALUE;
        final int idx = 0;
        final RubyFixnum fixnum = RubyFixnum.newFixnum(runtime, num);

        final AbstractDriverDefinition driver = new MyAbstractDriverDefinition();

        context.checking(new Expectations() {{
            allowing(ps).setLong(idx, num);
        }});
        driver.setPreparedStatementParam(ps, fixnum, idx);
    }
}
