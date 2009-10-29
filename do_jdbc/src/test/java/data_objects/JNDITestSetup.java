package data_objects;
import javax.naming.Context;
import javax.naming.NamingException;
import javax.naming.Reference;
import javax.naming.StringRefAddr;

import tyrex.naming.MemoryContext;
import tyrex.tm.RuntimeContext;

/**
 *
 */

public class JNDITestSetup {

    private final Context root;

    public JNDITestSetup(String uri, String jdbcDriverClassName, String jndiDatabase) throws NamingException{
        // reference to that implementation
        // http://commons.apache.org/dbcp/guide/jndi-howto.html
        // http://tyrex.sourceforge.net/naming.html
        System.setProperty(Context.INITIAL_CONTEXT_FACTORY,
            "tyrex.naming.MemoryContextFactory");
      Reference ref = new Reference("javax.sql.DataSource",
                                    "org.apache.commons.dbcp.BasicDataSourceFactory", null);
      ref.add(new StringRefAddr("driverClassName", jdbcDriverClassName));
      ref.add(new StringRefAddr("url", uri));

      // Construct a non-shared memory context
      root = new MemoryContext(null);
      Context ctx = root.createSubcontext( "comp" );
      ctx = ctx.createSubcontext( "env" );
      ctx = ctx.createSubcontext( "jdbc" );
      ctx.bind( jndiDatabase, ref );
    }

    public void setup() throws NamingException{
        // Associate the memory context with a new
        // runtime context and associate the runtime context
        // with the current thread
        RuntimeContext runCtx = RuntimeContext.newRuntimeContext( root, null );
        RuntimeContext.setRuntimeContext( runCtx );
    }

    public void teardown(){
        // Dissociate the runtime context from the thread
        RuntimeContext.unsetRuntimeContext();
    }
}
