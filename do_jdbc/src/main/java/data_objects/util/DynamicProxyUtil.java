package data_objects.util;

import javax.naming.InitialContext;
import javax.sql.DataSource;
import java.lang.reflect.Proxy;
import java.sql.*;

/**
 * @author Piotr Gega (pietia)
 */
public class DynamicProxyUtil {

    public final static boolean PROXY_ON;
    public final static boolean LOGGER_ON;

    public final static boolean LOG_CON;
    public final static boolean LOG_PS;
    public final static boolean LOG_ST;
    public final static boolean LOG_RS;
    public final static boolean LOG_RSMD;
    public final static boolean LOG_PMD;
    public final static boolean LOG_IC;
    public final static boolean LOG_DS;

    static {
        // TODO add support for env. variables
        // TODO add ability to select what should be proxied (i.e. only RSs)
        // TODO add ability to execution time of DO's methods (i.e. execute_query)
        // TODO add support for statistics
        // TODO ps = null
        PROXY_ON = false;
        LOGGER_ON = false;

        LOG_CON = true && PROXY_ON;
        LOG_PS = true && PROXY_ON;
        LOG_ST = true && PROXY_ON;
        LOG_RS = false && PROXY_ON;
        LOG_RSMD = false && PROXY_ON;
        LOG_PMD = false && PROXY_ON;
        LOG_IC = true && PROXY_ON;
        LOG_DS = true && PROXY_ON;
    }

    private DynamicProxyUtil() {
    }

    public static Connection proxyCON(Connection connection) {
        if (LOG_CON)
            return newProxiedCON(connection);
        return connection;
    }

    private static Connection newProxiedCON(Connection c) {
        return (Connection) Proxy.newProxyInstance(Connection.class.getClassLoader(),
                new Class[]{Connection.class}, new DynamicProxy(c));
    }

    public static PreparedStatement proxyPS(PreparedStatement preparedStatement) {
        if (LOG_PS)
            return newProxiedPreparedStatement(preparedStatement);
        return preparedStatement;
    }

    private static PreparedStatement newProxiedPreparedStatement(PreparedStatement preparedStatement) {
        return (PreparedStatement) Proxy.newProxyInstance(PreparedStatement.class.getClassLoader(),
                new Class[]{PreparedStatement.class}, new DynamicProxy(preparedStatement));
    }

    public static Statement proxyST(Statement statement) {
        if (LOG_ST)
            return newProxiedST(statement);
        return statement;
    }

    private static Statement newProxiedST(Statement statement) {
        return (Statement) Proxy.newProxyInstance(Statement.class.getClassLoader(),
                new Class[]{Statement.class}, new DynamicProxy(statement));
    }

    public static ResultSet proxyRS(ResultSet resultSet) {
        if (LOG_RS)
            return newProxiedRS(resultSet);
        return resultSet;
    }

    private static ResultSet newProxiedRS(ResultSet resultSet) {
        return (ResultSet) Proxy.newProxyInstance(ResultSet.class.getClassLoader(),
                new Class[]{ResultSet.class}, new DynamicProxy(resultSet));
    }

    public static ResultSetMetaData proxyRSMD(ResultSetMetaData rsmd) {
        if (LOG_RSMD)
            return newProxiedRSMD(rsmd);
        return rsmd;
    }

    private static ResultSetMetaData newProxiedRSMD(ResultSetMetaData rsmd) {
        return (ResultSetMetaData) Proxy.newProxyInstance(ResultSetMetaData.class.getClassLoader(),
                new Class[]{ResultSetMetaData.class}, new DynamicProxy(rsmd));
    }

    public static ParameterMetaData proxyPMD(ParameterMetaData pmd) {
        if (LOG_PMD)
            return newProxiedPMD(pmd);
        return pmd;
    }

    private static ParameterMetaData newProxiedPMD(ParameterMetaData pmd) {
        return (ParameterMetaData) Proxy.newProxyInstance(ParameterMetaData.class.getClassLoader(),
                new Class[]{ParameterMetaData.class}, new DynamicProxy(pmd));
    }

    public static InitialContext proxyIC(InitialContext initialContext) {
        if (LOG_IC)
            return newProxiedIC(initialContext);
        return initialContext;
    }

    private static InitialContext newProxiedIC(InitialContext initialContext) {
        return (InitialContext) Proxy.newProxyInstance(InitialContext.class.getClassLoader(),
                new Class[]{InitialContext.class}, new DynamicProxy(initialContext));
    }

    public static DataSource proxyDS(DataSource dataSource) {
        if (LOG_DS)
            return newProxiedDS(dataSource);
        return dataSource;
    }

    private static DataSource newProxiedDS(DataSource dataSource) {
        return (DataSource) Proxy.newProxyInstance(DataSource.class.getClassLoader(),
                new Class[]{DataSource.class}, new DynamicProxy(dataSource));
    }

}
