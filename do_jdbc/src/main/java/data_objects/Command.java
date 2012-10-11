package data_objects;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Formatter;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyNumeric;
import org.jruby.RubyRange;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.Block;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import data_objects.drivers.DriverDefinition;
import data_objects.errors.Errors;
import data_objects.util.JDBCUtil;


/**
 * Command Class
 *
 * @author alexbcoles
 * @author mkristian
 */
@SuppressWarnings("serial")
@JRubyClass(name = "Command")
public class Command extends DORubyObject {

    public final static String RUBY_CLASS_NAME = "Command";

    private List<RubyType> fieldTypes;

    private final static ObjectAllocator COMMAND_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            return new Command(runtime, klass);
        }
    };

    /**
     *
     * @param runtime
     * @param factory
     * @return
     */
    public static RubyClass createCommandClass(final Ruby runtime,
            DriverDefinition factory) {
        RubyModule doModule = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
        RubyClass superClass = doModule.getClass(RUBY_CLASS_NAME);
        RubyModule driverModule = (RubyModule) doModule.getConstant(factory
                .getModuleName());
        RubyClass commandClass = runtime.defineClassUnder("Command",
                superClass, COMMAND_ALLOCATOR, driverModule);
        commandClass.setInstanceVariable("@__factory", JavaEmbedUtils
                .javaToRuby(runtime, factory));
        commandClass.defineAnnotatedMethods(Command.class);
        setDriverDefinition(commandClass, runtime, factory);
        return commandClass;
    }

    /**
     *
     * @param runtime
     * @param klass
     */
    private Command(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }

    // -------------------------------------------------- DATAOBJECTS PUBLIC API

    // inherit initialize

    /**
     *
     * @param args
     * @return
     */
    @JRubyMethod(optional = 1, rest = true)
    public IRubyObject execute_non_query(IRubyObject[] args) {
        Ruby runtime = getRuntime();
        Connection connection_instance = (Connection) api.getInstanceVariable(this,
                "@connection");
        checkConnectionNotClosed(connection_instance);
        java.sql.Connection conn = connection_instance.getInternalConnection();

        IRubyObject insert_key = runtime.getNil();
        RubyClass resultClass = Result.createResultClass(runtime, driver);
        // affectedCount == 1 means 1 updated row
        // or 1 row in result set that represents returned key (insert...returning),
        // other values represents number of updated rows
        int affectedCount = 0;
        PreparedStatement sqlStatement = null;
        // if usePreparedStatement returns false
        Statement sqlSimpleStatement = null;
        java.sql.ResultSet keys = null;

        // String sqlText = prepareSqlTextForPs(api.getInstanceVariable(recv,
        // "@text").asJavaString(), recv, args);
        String doSqlText = api.convertToRubyString(
                api.getInstanceVariable(this, "@text")).getUnicodeValue();
        String sqlText = prepareSqlTextForPs(doSqlText, args);

        // additional callback for driver specific SQL statement changes
        sqlText = driver.prepareSqlTextForPs(sqlText, args);

        boolean usePS = usePreparedStatement(sqlText, args);
        boolean hasReturnParam = false;

        try {
            if (usePS) {
                if (driver.supportsConnectionPrepareStatementMethodWithGKFlag()) {
                    sqlStatement = conn.prepareStatement(sqlText,
                    driver.supportsJdbcGeneratedKeys() ? Statement.RETURN_GENERATED_KEYS : Statement.NO_GENERATED_KEYS);
                } else {
                    // If java.sql.PreparedStatement#getGeneratedKeys() is not supported,
                    // then it is important to call java.sql.Connection#prepareStatement(String)
                    // -- with just a single parameter -- rather java.sql.Connection#
                    // prepareStatement(String, int) (and passing in Statement.NO_GENERATED_KEYS).
                    // Some less-than-complete JDBC drivers do not implement all of
                    // the overloaded prepareStatement methods: the main culprit
                    // being SQLiteJDBC which currently throws an ugly (and cryptic)
                    // "NYI" SQLException if Connection#prepareStatement(String, int)
                    // is called.
                    sqlStatement = conn.prepareStatement(sqlText);
                }

                hasReturnParam = prepareStatementFromArgs(sqlText, sqlStatement, args);
            } else {
                sqlSimpleStatement = conn.createStatement();
            }

            long startTime = System.currentTimeMillis();
            if (usePS) {
                boolean hasResult = sqlStatement.execute();
                if (hasResult) {
                    keys = sqlStatement.getResultSet();
                } else {
                    affectedCount = sqlStatement.getUpdateCount();
                }
            } else {
                sqlSimpleStatement.execute(sqlText);
            }
            long endTime = System.currentTimeMillis();

            if (isDebug()) {
              if (usePS)
                  debug(driver.statementToString(sqlStatement), Long.valueOf(endTime - startTime));
              else
                  debug(sqlText, Long.valueOf(endTime - startTime));
            }

            if (usePS && keys == null) {
                if (driver.supportsJdbcGeneratedKeys()) {
                    // Derby, H2, and MySQL all support getGeneratedKeys(), but only
                    // to varying extents.
                    //
                    // However, javaConn.getMetaData().supportsGetGeneratedKeys()
                    // currently returns FALSE for the Derby driver, as its support
                    // is limited. As such, we use supportsJdbcGeneratedKeys() from
                    // our own driver definition.
                    //
                    // See http://issues.apache.org/jira/browse/DERBY-242
                    // See http://issues.apache.org/jira/browse/DERBY-2631
                    // (Derby only supplies getGeneratedKeys() for auto-incremented
                    // columns)
                    //

                    // apparently the prepared statements always provide the
                    // generated keys
                    keys = sqlStatement.getGeneratedKeys();

                } else if (hasReturnParam) {
                    // Used in Oracle for INSERT ... RETURNING ... INTO ... statements
                    insert_key = runtime.newFixnum(driver.getPreparedStatementReturnParam(sqlStatement));
                } else {
                    // If there is no support, then a custom method can be defined
                    // to return a ResultSet with keys
                    keys = driver.getGeneratedKeys(conn);
                    // The OpenEdge driver needs additional information
                    if (keys == null)
                        keys = driver.getGeneratedKeys(conn, sqlStatement, sqlText);
                }
            }
            if (usePS && keys != null) {
                insert_key = unmarshal_id_result(keys);
                if (insert_key != runtime.getNil())
                    affectedCount = (affectedCount > 0) ? affectedCount : 1;
            }

        } catch (SQLException sqle) {
            throw Errors.newQueryError(runtime, driver, sqle, usePS ? sqlStatement : sqlSimpleStatement);
        } finally {
            if (usePS) {
                JDBCUtil.close(keys,sqlStatement);
            } else {
                JDBCUtil.close(keys,sqlSimpleStatement);
            }
            keys = null;
            sqlStatement = null;
            sqlSimpleStatement = null;
        }

        IRubyObject affected_rows = runtime.newFixnum(affectedCount);

        return api.callMethod(resultClass, "new",
                new IRubyObject[] {this, affected_rows, insert_key });
    }

    /**
     *
     * @param args
     * @return
     */
    @JRubyMethod(optional = 1, rest = true)
    public IRubyObject execute_reader(IRubyObject[] args) {
        Ruby runtime = getRuntime();
        Connection connection_instance = (Connection) api.getInstanceVariable(this,
                "@connection");
        checkConnectionNotClosed(connection_instance);

        java.sql.Connection conn = connection_instance.getInternalConnection();

        RubyClass readerClass = Reader.createReaderClass(runtime, driver);
        boolean inferTypes = false;
        int columnCount = 0;
        PreparedStatement sqlStatement = null;
        ResultSet resultSet = null;
        ResultSetMetaData metaData;

        // instantiate a new reader
        Reader reader = (Reader) readerClass.newInstance(runtime.getCurrentContext(),
                                                     new IRubyObject[] { }, Block.NULL_BLOCK);

        // execute the query
        try {
            String doSqlText = api.convertToRubyString(
                    api.getInstanceVariable(this, "@text")).getUnicodeValue();
            String sqlText = prepareSqlTextForPs(doSqlText, args);

            sqlStatement = conn.prepareStatement(
                           sqlText,
                           driver.supportsJdbcScrollableResultSets() ? ResultSet.TYPE_SCROLL_INSENSITIVE : ResultSet.TYPE_FORWARD_ONLY,
                           ResultSet.CONCUR_READ_ONLY);

            prepareStatementFromArgs(sqlText, sqlStatement, args);

            long startTime = System.currentTimeMillis();
            resultSet = sqlStatement.executeQuery();
            long endTime = System.currentTimeMillis();
 
            if (isDebug()) {
                 debug(driver.statementToString(sqlStatement), Long.valueOf(endTime - startTime));
            }

            metaData = resultSet.getMetaData();
            columnCount = metaData.getColumnCount();

            // reduce columnCount by 1 if RAW_RNUM_ is present as last column
            // (generated by DataMapper Oracle adapter to simulate LIMIT and OFFSET)
            if (metaData.getColumnName(columnCount).equals("RAW_RNUM_"))
                columnCount--;

            // pass the response to the Reader
            reader.resultSet = resultSet;

            // pass reference to the Statement object and close it later in the Reader
            reader.statement = sqlStatement;

            // save the field count in Reader
            reader.fieldCount = columnCount;

            // get the field types
            List<String> fieldNames = new ArrayList<String>(columnCount);

            // If no types are passed in, infer them
            if (fieldTypes == null || fieldTypes.isEmpty()) {
                fieldTypes = new ArrayList<RubyType>();
                inferTypes = true;
            } else if (fieldTypes.size() != columnCount) {
                // Wrong number of fields passed to set_types. Close the reader
                // and raise an error.
                api.callMethod(reader, "close");
                throw runtime.newArgumentError(String.format("Field-count mismatch. Expected %1$d fields, but the query yielded %2$d",
                        fieldTypes.size(), columnCount));
            }

            // for each field
            for (int i = 0; i < columnCount; i++) {
                int col = i + 1;
                // downcase the field name
                fieldNames.add(metaData.getColumnLabel(col));

                if (inferTypes) {
                    // infer the type if no types passed
                    fieldTypes.add(
                            driver.jdbcTypeToRubyType(metaData.getColumnType(col),
                            metaData.getPrecision(col), metaData.getScale(col)));
                }
            }

            // set the reader field names and types (guessed or otherwise)
            reader.fieldNames = fieldNames;
            reader.fieldTypes = fieldTypes;

        } catch (SQLException sqle) {
            // XXX sqlite3 jdbc driver happily throws an exception if the result set is empty :P
            // this sets up a minimal empty reader
            if (sqle.getMessage().equals("query does not return results")) {

                // pass the response to the Reader
                reader.resultSet = resultSet;

                // pass reference to the Statement object and close it later in the Reader
                reader.statement = sqlStatement;

                // get the field types
                List<String> fieldNames = new ArrayList<String>();
                // for each field
                try {
                    metaData = sqlStatement.getMetaData();
                    for (int i = 0; i < columnCount; i++) {
                        int col = i + 1;
                        // downcase the field name
                        fieldNames.add(metaData.getColumnLabel(col));

                        // infer the type if no types passed
                        fieldTypes.add(
                                driver.jdbcTypeToRubyType(metaData.getColumnType(col),
                                metaData.getPrecision(col), metaData.getScale(col)));
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                }

                // set the reader field names and types (guessed or otherwise)
                reader.fieldNames = fieldNames;
                return reader;
            }

            api.callMethod(reader, "close");
            throw Errors.newQueryError(runtime, driver, sqle, sqlStatement);
        }

        // return the reader
        return reader;
    }

    /**
     *
     * @param args
     * @return
     */
    @JRubyMethod(rest = true)
    public IRubyObject set_types(IRubyObject[] args) {
        Ruby runtime = getRuntime();
        RubyArray types = RubyArray.newArray(runtime, args);
        fieldTypes = new ArrayList<RubyType>(types.size());

        for (IRubyObject arg : args) {
            if (arg instanceof RubyClass) {
                fieldTypes.add(RubyType.getRubyType((RubyClass) arg));
            } else if (arg instanceof RubyArray) {
                for (IRubyObject sub_arg : arg.convertToArray().toJavaArray()) {
                    if (sub_arg instanceof RubyClass) {
                        fieldTypes.add(RubyType.getRubyType((RubyClass) sub_arg));
                    } else {
                        throw runtime.newArgumentError("Invalid type given");
                    }
                }
            } else {
                throw runtime.newArgumentError("Invalid type given");
            }
        }

        return types;
    }

    // ---------------------------------------------------------- HELPER METHODS

    /**
     *
     * @param conn
     */
    private void checkConnectionNotClosed(Connection conn) {
        try {
            java.sql.Connection internal_connection = conn.getInternalConnection();
            if (internal_connection == null) {
                throw Errors.newConnectionError(getRuntime(), "This connection has already been closed.");
            }
            if(internal_connection.isClosed()) {
                /*
                 * Try reconnecting here if the connection has failed without
                 * us asking for it to be closed.
                 */
                conn.connect();
                internal_connection = conn.getInternalConnection();
                if (internal_connection == null || internal_connection.isClosed()) {
                    throw Errors.newConnectionError(getRuntime(), "This connection has already been closed.");
                }
            }
        } catch (SQLException ignored) {
        }
    }

    /**
     * Unmarshal a java.sql.Resultset containing generated keys, and return a
     * Ruby Fixnum with the last key.
     *
     * @param rs
     * @return
     * @throws java.sql.SQLException
     */
    public IRubyObject unmarshal_id_result(ResultSet rs) throws SQLException {
        try {
            if (rs.next()) {
                if (rs.getMetaData().getColumnCount() > 0) {
                    // TODO: Need to do check for other types here, as keys could be
                    // of type Integer, Long or String
                    return getRuntime().newFixnum(rs.getLong(1));
                }
            }
            return getRuntime().getNil();
        } finally {
            JDBCUtil.close(rs);
        }
    }

    /**
     * Assist with the formatting of SQL Text Strings for PreparedStatements.
     *
     * In many cases, DO SQL Text syntax matches exactly with the syntax for
     * JDBC PreparedStatement SQL Text. However, there are differences when
     * RubyArrays and RubyRanges are passed as parameters. DO handles these
     * parameters with a single "?", whereas for JDBC these will need to be
     * converted appropriately to "(?,?)" or "(? AND ?)".
     *
     * This method appropriately converts the question mark syntax from
     * DataObjects-style to JDBC PreparedStatement-style.
     *
     * @param doSqlText
     * @param args
     * @return a SQL Text java.lang.String formatted for preparing a PreparedStatement
     */
    private String prepareSqlTextForPs(String doSqlText, IRubyObject[] args) {

        if (args.length == 0) return doSqlText;
        // long timeStamp = System.currentTimeMillis(); // XXX for debug
        // System.out.println(""+timeStamp+" SQL before replacements @: " + doSqlText); // XXX for debug
        String psSqlText = doSqlText;
        int addedSymbols=0;

        for (int i = 0; i < args.length; i++) {

            if (args[i] instanceof RubyArray) {
                // replace "?" with "(?,?)"
                // calculate replacement string, depending on the length of the
                // RubyArray - i.e. should it be "(?)" or "(?,?,?)
                // System.out.println(""+timeStamp+" RubyArray @: " + args[i]); // XXX for debug
                StringBuilder replaceSb = new StringBuilder("(");
                int arrayLength = args[i].convertToArray().getLength();

                for (int j = 0; j < arrayLength; j++) {
                    replaceSb.append("?");
                    if (j < arrayLength - 1) replaceSb.append(",");
                }
                replaceSb.append(")");

                Pattern pp = Pattern.compile("\\?");
                Matcher pm = pp.matcher(psSqlText);
                StringBuffer sb = new StringBuffer();

                int count = 0;
                lbWhile:
                while (pm.find()) {
                    if (count == (i+addedSymbols)){
                        pm.appendReplacement(sb, replaceSb.toString());
                        addedSymbols += arrayLength-1;
                        break lbWhile;
                    }
                    count++;
                }
                pm.appendTail(sb);
                psSqlText = sb.toString();
            } else if (args[i] instanceof RubyRange) {
                // replace "?" with "(?,?)"
                // System.out.println(""+timeStamp+" RubyRange @: " + args[i]); // XXX for debug
                Pattern pp = Pattern.compile("\\?");
                Matcher pm = pp.matcher(psSqlText);
                StringBuffer sb = new StringBuffer();

                int count = 0;
                lbWhile:
                while (pm.find()) {
                    if (count ==(i+addedSymbols)){
                        pm.appendReplacement(sb, "? AND ?"); // XXX was (? AND ?)
                        addedSymbols += 1;
                        break lbWhile;
                    }
                    count++;
                }
                pm.appendTail(sb);
                psSqlText = sb.toString();
            } else {
                // System.out.println(""+timeStamp+" Nothing @: " + args[i]); // XXX for debug
                // do nothing
            }
        }
        // System.out.println(""+timeStamp+" SQL after replacements @: " + psSqlText); // XXX for debug
        return psSqlText;
    }

    /**
     * Check SQL string and tell if PreparedStatement or Statement should be used.
     * Necessary for Oracle driver as Statement should be used for CREATE TRIGGER statements.
     *
     * @param doSqlText
     * @param args
     * @return true if PreparedStatement should be used or false if Statement should be used
     */
    private boolean usePreparedStatement(String doSqlText, IRubyObject[] args) {
        // if parameters are present then use PreparedStatement
        if (args.length > 0) return true;

        // check if SQL starts with CREATE
        Pattern p = Pattern.compile("\\A\\s*(CREATE|DROP)", Pattern.CASE_INSENSITIVE);
        Matcher m = p.matcher(doSqlText);
        return !m.find();
    }

    /**
     * Assist with setting the parameter values on a PreparedStatement
     *
     * @param sqlText
     * @param ps the PreparedStatement for which parameters should be set
     * @param args an array of parameter values
     *
     * @return true if there is return parameter, false if there is not
     */
    private boolean prepareStatementFromArgs(String sqlText, PreparedStatement ps,
            IRubyObject[] args) {
        int index = 1;
        boolean hasReturnParam = false;
        try {
            int psCount = ps.getParameterMetaData().getParameterCount();
            // fail fast
            if (args.length > psCount) {
                throw getRuntime().newArgumentError(
                        "Binding mismatch: " + args.length + " for " + psCount);
            }
            for (IRubyObject arg : args) {

                // Handle multiple valued arguments, i.e. arrays + ranges

                if (arg instanceof RubyArray) {
                    // Handle a RubyArray passed into a query
                    //
                    // NOTE: This should not call ps.setArray(i,v) as this is
                    // designed to work with the SQL Array type, and in most cases
                    // is not what we want.
                    // Instead, this functionality is for breaking down a Ruby
                    // array of ["a","b","c"] into SQL "('a','b','c')":
                    //
                    // So, in this case, we actually want to augment the number of
                    // ? params in the PreparedStatement query appropriately.

                    RubyArray arrayValues = arg.convertToArray();

                    for (int j = 0; j < arrayValues.getLength(); j++) {
                        driver.setPreparedStatementParam(ps, arrayValues
                                .eltInternal(j), index++);
                    }
                } else if (arg instanceof RubyRange) {
                    // Handle a RubyRange passed into a query
                    //
                    // NOTE: see above - need to augment the number of ? params
                    // in the PreparedStatement: (? AND ?)

                    RubyRange range_value = (RubyRange) arg;

                    driver.setPreparedStatementParam(ps, range_value.first(), index++);
                    driver.setPreparedStatementParam(ps, range_value.last(), index++);

                } else {
                    // Otherwise, handle each argument
                    driver.setPreparedStatementParam(ps, arg, index++);
                }
            }

            // callback for binding RETURN ... INTO ... output parameter
            if (driver.registerPreparedStatementReturnParam(sqlText, ps, index)) {
                index++;
                hasReturnParam = true;
            }

            if ((index - 1) < psCount) {
                throw getRuntime().newArgumentError(
                        "Binding mismatch: " + (index - 1) + " for " + psCount);
            }
            return hasReturnParam;
        } catch (SQLException sqle) {
            // TODO: possibly move this exception string parsing somewhere else
            Pattern pattern = Pattern.compile("Parameter index out of bounds. (\\d+) is not between valid values of (\\d+) and (\\d+)");
                                // POSTGRES: The column index is out of range: 2, number of columns: 1.
                                // POSTGRES SQL STATE: 22023 (22023 "INVALID PARAMETER VALUE" invalid_parameter_value)
                                // SQLITE3:  Does not throw a SQLException!
                                // H2: Invalid value 2 for parameter parameterIndex [90008-63]
                                // HSQLDB:      Invalid argument in JDBC call: parameter index out of range: 2
                                // DERBY:       The parameter position '2' is out of range.  The number of parameters for this prepared  statement is '1'
                                // DERbY SQL CODE:  XCL13
            Matcher matcher = pattern.matcher(sqle.getMessage());
            if (matcher.matches()) {
                throw getRuntime().newArgumentError(
                        String.format("Binding mismatch: %1$d for %2$d",
                                Integer.parseInt(matcher.group(1)), Integer
                                        .parseInt(matcher.group(2))));
            } else {
                throw Errors.newSqlError(getRuntime(), driver, sqle);
            }
        }
    }


    /**
     * Output a log message
     *
     * @param logMessage
     * @param executionTime
     */
    private void debug(String logMessage, Long executionTime) {
      Ruby runtime = getRuntime();
      Connection connection_instance = (Connection) api.getInstanceVariable(this,
          "@connection");
      RubyModule doModule  = runtime.getModule(DATA_OBJECTS_MODULE_NAME);
      RubyClass loggerClass = doModule.getClass("Logger");
      RubyClass messageClass = loggerClass.getClass("Message");

      IRubyObject loggerMsg  = messageClass.newInstance(runtime.getCurrentContext(),
          runtime.newString(logMessage),    // query
          runtime.newString(""),            // start
          runtime.newFixnum(executionTime), // duration
          Block.NULL_BLOCK);

      api.callMethod(connection_instance, "log", loggerMsg);
    }

    /**
     * returns if the debug mode is turned on.
     */
    private boolean isDebug() {
        RubyModule driverModule = (RubyModule) getRuntime().getModule(
                DATA_OBJECTS_MODULE_NAME).getConstant(driver.getModuleName());
        IRubyObject logger = api.callMethod(driverModule, "logger");
        int level = RubyNumeric.fix2int(api.callMethod(logger, "level"));
        return level == 0;
    }
}
