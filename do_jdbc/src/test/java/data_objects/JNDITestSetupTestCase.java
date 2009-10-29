package data_objects;
import java.sql.Connection;

import javax.naming.InitialContext;
import javax.sql.DataSource;

import junit.framework.TestCase;


public class JNDITestSetupTestCase extends TestCase {

    public void test() throws Exception{
        String JNDI = "mydb";
        JNDITestSetup jndi = new JNDITestSetup("jdbc:sqlite::memory:", "org.sqlite.JDBC", JNDI );

        jndi.setup();

        DataSource ds = (DataSource) new InitialContext().lookup("java:comp/env/jdbc/" + JNDI);
        assertNotNull(ds);
        Connection conn = ds.getConnection();
        assertNotNull(conn);
        conn.close();

        jndi.teardown();
    }
}
