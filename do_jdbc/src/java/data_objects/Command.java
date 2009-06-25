package data_objects;

import static data_objects.DataObjects.DATA_OBJECTS_MODULE_NAME;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyNil;
import org.jruby.RubyNumeric;
import org.jruby.RubyRange;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.Java;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.javasupport.JavaObject;
import org.jruby.runtime.Block;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

import data_objects.drivers.DriverDefinition;

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

    private final static ObjectAllocator COMMAND_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klass) {
            Command instance = new Command(runtime, klass);
            return instance;
        }
    };

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

    private Command(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }

    // -------------------------------------------------- DATAOBJECTS PUBLIC API

    // inherit initialize

    @JRubyMethod(optional = 1, rest = true)
    public IRubyObject execute_non_query(IRubyObject[] args) {
        Ruby runtime = getRuntime();
        IRubyObject connection_instance = api.getInstanceVariable(this,
                "@connection");
        IRubyObject wrapped_jdbc_connection = api.getInstanceVariable(
                connection_instance, "@connection");
        if (wrapped_jdbc_connection.isNil()) {
            throw driver.newDriverError(runtime,
                    "This connection has already been closed.");
        }
        java.sql.Connection conn = getConnection(wrapped_jdbc_connection);

        IRubyObject insert_key = runtime.getNil();
        RubyClass resultClass = Result.createResultClass(runtime, driver);
        // affectedCount == 1 means 1 updated row
        // or 1 row in result set that represents returned key (insert...returning),
        // other values represents numer of updated rows
        int affectedCount = 0;
        PreparedStatement sqlStatement = null;
        java.sql.ResultSet keys = null;

        // String sqlText = prepareSqlTextForPs(api.getInstanceVariable(recv,
        // "@text").asJavaString(), recv, args);
        String doSqlText = api.convertToRubyString(
                api.getInstanceVariable(this, "@text")).getUnicodeValue();
        String sqlText = prepareSqlTextForPs(doSqlText, args);
        List<IRubyObject> list = new ArrayList<IRubyObject>();
        for( IRubyObject o: args){
            if (o != null){
                list.add(o);
            }
        }
        args = list.toArray(new IRubyObject[list.size()]);
        try {
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

            prepareStatementFromArgs(sqlStatement, args);

            //javaConn.setAutoCommit(true); // hangs with autocommit set to false
            // sqlStatement.setMaxRows();
            long startTime = System.currentTimeMillis();
            try {
                if (sqlText.contains("RETURNING")) {
                    keys = sqlStatement.executeQuery();
                } else {
                    affectedCount = sqlStatement.executeUpdate();
                }
            } catch (SQLException sqle) {
                // This is to handle the edge case of SELECT sleep(1):
                // an executeUpdate() will throw a SQLException if a SELECT
                // is passed, so we try the same query again with execute()
                affectedCount = 0;
                sqlStatement.execute();
            }
            long endTime = System.currentTimeMillis();

            debug(driver.toString(sqlStatement), Long.valueOf(endTime
                    - startTime));

            if (keys == null) {
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

                } else {
                    // If there is no support, then a custom method can be defined
                    // to return a ResultSet with keys
                    keys = driver.getGeneratedKeys(conn);
                }
            }
            if (keys != null) {
                insert_key = unmarshal_id_result(keys);
                affectedCount = (affectedCount > 0) ? affectedCount : 1;
            }

            // not needed as it will be closed in the finally clause
            // sqlStatement.close();
            // sqlStatement = null;
        } catch (SQLException sqle) {
            // TODO: log
            // sqle.printStackTrace();
            throw newQueryError(runtime, sqle, sqlStatement);
        } finally {
            if (sqlStatement != null) {
                try {
                    sqlStatement.close();
                } catch (SQLException sqle2) {
                }
            }
        }

        // return nil if no updates are made
        if (affectedCount <= 0) {
            return runtime.getNil();
        }

        IRubyObject affected_rows = runtime.newFixnum(affectedCount);

        IRubyObject result = api.callMethod(resultClass, "new",
                new IRubyObject[] { this, affected_rows, insert_key });
        return result;
    }

    @JRubyMethod(optional = 1, rest = true)
    public IRubyObject execute_reader(IRubyObject[] args) {
        Ruby runtime = getRuntime();
        IRubyObject connection_instance = api.getInstanceVariable(this,
                "@connection");
        IRubyObject wrapped_jdbc_connection = api.getInstanceVariable(
                connection_instance, "@connection");
        if (wrapped_jdbc_connection.isNil()) {
            throw driver.newDriverError(runtime,
                    "This connection has already been closed.");
        }
        java.sql.Connection conn = getConnection(wrapped_jdbc_connection);

        RubyClass readerClass = Reader.createReaderClass(runtime, driver);
        boolean inferTypes = false;
        int columnCount = 0;
        PreparedStatement sqlStatement = null;
        ResultSet resultSet = null;
        ResultSetMetaData metaData = null;

        // instantiate a new reader
        IRubyObject reader = readerClass.newInstance(runtime.getCurrentContext(),
                                                     new IRubyObject[] { }, Block.NULL_BLOCK);

        // execute the query
        try {
            String sqlText = prepareSqlTextForPs(api.getInstanceVariable(this,
                    "@text").asJavaString(), args);

            List<IRubyObject> list = new ArrayList<IRubyObject>();
            for( IRubyObject o: args){
                if (o != null){
                    list.add(o);
                }
            }
            args = list.toArray(new IRubyObject[list.size()]);

            sqlStatement = conn.prepareStatement(
                           sqlText,
                           driver.supportsJdbcScrollableResultSets() ? ResultSet.TYPE_SCROLL_INSENSITIVE : ResultSet.TYPE_FORWARD_ONLY,
                           ResultSet.CONCUR_READ_ONLY);

            // sqlStatement.setMaxRows();
            prepareStatementFromArgs(sqlStatement, args);

            long startTime = System.currentTimeMillis();
            resultSet = sqlStatement.executeQuery();
            long endTime = System.currentTimeMillis();

            debug(driver.toString(sqlStatement), Long
                    .valueOf(endTime - startTime));

            metaData = resultSet.getMetaData();
            columnCount = metaData.getColumnCount();

            // pass the response to the reader
            IRubyObject wrappedResultSet = Java.java_to_ruby(this, JavaObject
                    .wrap(getRuntime(), resultSet), Block.NULL_BLOCK);
            reader.getInstanceVariables().setInstanceVariable("@reader",
                    wrappedResultSet);

            wrappedResultSet.dataWrapStruct(resultSet);

            // handle each result

            // mark the reader as opened
            api.setInstanceVariable(reader, "@opened", runtime.getTrue());
            // TODO: if no response return nil

            api.setInstanceVariable(reader, "@position", runtime.newFixnum(0));

            // save the field_count in reader
            api.setInstanceVariable(reader, "@field_count", runtime.newFixnum(columnCount));

            // get the field types
            RubyArray field_names = runtime.newArray();
            IRubyObject field_types = api.getInstanceVariable(this,
                    "@field_types");

            // If no types are passed in, infer them
            if (field_types == null) {
                field_types = runtime.newArray();
                inferTypes = true;
            } else {
                int fieldTypesCount = field_types.convertToArray().getLength();
                if (field_types.isNil() || fieldTypesCount == 0) {
                    field_types = runtime.newArray();
                    inferTypes = true;
                } else if (fieldTypesCount != columnCount) {
                    // Wrong number of fields passed to set_types. Close the reader
                    // and raise an error.
                    api.callMethod(reader, "close");
                    throw runtime.newArgumentError(String.format("Field-count mismatch. Expected %1$d fields, but the query yielded %2$d",
                                                                 fieldTypesCount,
                                                                 columnCount));
                }
            }

            // for each field
            for (int i = 0; i < columnCount; i++) {
                RubyString field_name = runtime.newString(metaData.getColumnName(i + 1));
                // infer the type if no types passed
                field_names.push_m(new IRubyObject[] { field_name });

                if (inferTypes) {
                    // TODO: do something
                }
            }

            // set the reader @field_names and @types (guessed or otherwise)
            api.setInstanceVariable(reader, "@fields", field_names);
            api.setInstanceVariable(reader, "@field_types", field_types);

            // keep the statement open

            // TODO why keep it open ???

            //sqlStatement.close();
            //sqlStatement = null;
        } catch (SQLException sqle) {
            // TODO: log sqle.printStackTrace();
            // XXX sqlite3 jdbc driver happily throws an exception if the result set is empty :P
            // this sets up a minimal empty reader
            if (sqle.getMessage().equals("query does not return results")) {
                IRubyObject wrappedResultSet = Java.java_to_ruby(this,
                        JavaObject.wrap(getRuntime(), resultSet),
                        Block.NULL_BLOCK);
                reader.getInstanceVariables().setInstanceVariable("@reader",
                        wrappedResultSet);

                wrappedResultSet.dataWrapStruct(resultSet);
                // get the field types
                RubyArray field_names = runtime.newArray();
                // for each field
                try {
                    metaData = sqlStatement.getMetaData();
                    for (int i = 0; i < columnCount; i++) {
                        RubyString field_name = runtime.newString(metaData
                                .getColumnName(i + 1));
                        // infer the type if no types passed
                        field_names.push_m(new IRubyObject[] { field_name });

                        if (inferTypes) {
                            // TODO: do something
                        }
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                }

                // set the reader @field_names and @types (guessed or otherwise)
                api.setInstanceVariable(reader, "@fields", field_names);
                return reader;
            }

            throw newQueryError(runtime, sqle, sqlStatement);
        } finally {
            //if (sqlStatement != null) {
            //    try {
            //        sqlStatement.close();
            //    } catch (SQLException stsqlex) {
            //    }
            //}
        }

        // return the reader
        return reader;
    }

    @JRubyMethod(rest = true)
    public IRubyObject set_types(IRubyObject[] args) {
        Ruby runtime = getRuntime();
        RubyArray types = RubyArray.newArray(runtime, args);
        RubyArray type_strings = RubyArray.newArray(runtime);

        for (IRubyObject arg : args) {
            if (arg instanceof RubyClass) {
                type_strings.append(arg);
            } else if (arg instanceof RubyArray) {
                for (IRubyObject sub_arg : arg.convertToArray().toJavaArray()) {
                    if (sub_arg instanceof RubyClass) {
                        type_strings.append(sub_arg);
                    } else {
                        throw runtime.newArgumentError("Invalid type given");
                    }
                }
            } else {
                throw runtime.newArgumentError("Invalid type given");
            }
        }

        api.setInstanceVariable(this, "@field_types", type_strings);
        return types;
    }

    // ---------------------------------------------------------- HELPER METHODS

    private static java.sql.Connection getConnection(IRubyObject recv) {
        java.sql.Connection conn = (java.sql.Connection) recv.dataGetStruct();
        return conn;
    }

    /**
     * Unmarshal a java.sql.Resultset containing generated keys, and return a
     * Ruby Fixnum with the last key.
     *
     * @param runtime
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
            try {
                rs.close();
            } catch (Exception e) {}
        }
    }

    private RaiseException newQueryError(Ruby runtime, SQLException sqle,
            Statement statement) {
        // TODO: provide an option to display extended debug information, for
        // driver developers, etc. Otherwise, keep it off to keep noise down for
        // end-users.
        Pattern p = Pattern.compile("Statement parameter (\\d+) not set.");
        Matcher m = p.matcher(sqle.getMessage());

        if (m.matches()) {
            return runtime.newArgumentError("Binding mismatch: 0 for " + m.group(1));
        } else {
            return driver.newDriverError(runtime, sqle, statement);
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
     * @param recv
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
                StringBuffer replaceSb = new StringBuffer("(");
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
            } else if(args[i] instanceof RubyNil){
                // TODO needs something like this for 'IS NOT ?'
                Pattern pp = Pattern.compile("IS \\?");
                Matcher pm = pp.matcher(psSqlText);
                StringBuffer sb = new StringBuffer();

                int count = 0;
                lbWhile: while (pm.find()) {
                    if (count == (i + addedSymbols)) {
                        pm.appendReplacement(sb, "IS NULL");
                        args[i] = null;
                        addedSymbols -= 1;
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
     * Assist with setting the parameter values on a PreparedStatement
     *
     * @param ps the PreparedStatement for which parameters should be set
     * @param recv
     * @param args an array of parameter values
     */
    private void prepareStatementFromArgs(PreparedStatement ps,
            IRubyObject[] args) {
        int index = 1;
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
            if ((index - 1) < psCount) {
                throw getRuntime().newArgumentError(
                        "Binding mismatch: " + (index - 1) + " for " + psCount);
            }
        } catch (SQLException sqle) {
            // TODO: log sqle.printStackTrace();
            // TODO: possibly move this exception string parsing somewhere else
            Pattern pattern = Pattern
                    .compile("Parameter index out of bounds. (\\d+) is not between valid values of (\\d+) and (\\d+)");
            Matcher matcher = pattern.matcher(sqle.getMessage());
            if (matcher.matches()) {
                throw getRuntime().newArgumentError(
                        String.format("Binding mismatch: %1$d for %2$d",
                                Integer.parseInt(matcher.group(1)), Integer
                                        .parseInt(matcher.group(2))));
            } else {
                throw driver.newDriverError(getRuntime(), sqle);
            }
        }
    }

    // /**
    // * Output a log message
    // *
    // * @param runtime
    // * @param logMessage
    // */
    // private void debug(String logMessage) {
    // debug(logMessage, null);
    // }

    /**
     * Output a log message
     *
     * @param runtime
     * @param logMessage
     * @param executionTime
     */
    private void debug(String logMessage, Long executionTime) {
        RubyModule driverModule = (RubyModule) getRuntime().getModule(
                DATA_OBJECTS_MODULE_NAME).getConstant(driver.getModuleName());
        IRubyObject logger = api.callMethod(driverModule, "logger");
        int level = RubyNumeric.fix2int(api.callMethod(logger, "level"));

        if (level == 0) {
            StringBuffer msgSb = new StringBuffer();

            if (executionTime != null) {
                msgSb.append("(").append(executionTime).append(") ");
            }

            msgSb.append(logMessage);

            api.callMethod(logger, "debug", getRuntime().newString(
                    msgSb.toString()));
        }
    }

}
