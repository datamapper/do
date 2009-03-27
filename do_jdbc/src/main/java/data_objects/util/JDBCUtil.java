package data_objects.util;

import java.sql.SQLException;

/**
 *
 * @author alexbcoles
 */
public final class JDBCUtil {

    /**
     * Close a java.sql.Connection, while ignoring any database errors (in the
     * form of SQLException) that may result from freeing the resource.
     *
     * @param conn
     * @see java.sql.Connection#close()
     */
    public static void close(java.sql.Connection conn) {
        if (conn != null) {
            try {
                conn.close();
            } catch (SQLException ignore) {
            }
        }
    }

    /**
     * Close a java.sql.Statement, while ignoring any database errors (in the
     * form of SQLException) that may result from freeing the resource.
     *
     * @param stmt
     * @see java.sql.Statement#close()
     */
    public static void close(java.sql.Statement stmt) {
        if (stmt != null) {
            try {
                stmt.close();
            } catch (SQLException ignore) {
            }
        }
    }

    /**
     * Close a java.sql.ResultSet, while ignoring any database errors (in the
     * form of SQLException) that may result from freeing the resource.
     *
     * @param rs
     * @see java.sql.ResultSet#close()
     */
    public static void close(java.sql.ResultSet rs) {
        if (rs != null) {
            try {
                rs.close();
            } catch (SQLException ignore) {
            }
        }
    }

    // private constructor
    private JDBCUtil() {
    }

}
