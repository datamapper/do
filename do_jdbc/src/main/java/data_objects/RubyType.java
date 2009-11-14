package data_objects;

import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.*;
import java.sql.Types;
import java.util.HashMap;
import java.util.Map;

/**
 * Enum representing the Ruby classes that DataObjects must handle (marshal,
 * unmarshal, convert to equivalent JDBC/Java types, etc.)
 *
 * @author alexbcoles
 */
public enum RubyType {

    CLASS      ("Class"),
    OBJECT     ("Object"),
    STRING     ("String"),
    DATE       ("Date"),
    DATE_TIME  ("DateTime"),
    TIME       ("Time"),
    TRUE_CLASS ("TrueClass"),
    FALSE_CLASS("FalseClass"),
    INTEGER    ("Integer"),
    FIXNUM     ("Fixnum"),
    BIGNUM     ("Bignum"),
    RATIONAL   ("Rational"),
    FLOAT      ("Float"),
    BIG_DECIMAL("BigDecimal"),
    BYTE_ARRAY ("Extlib::ByteArray"),      // Extlib::ByteArray < String
    REGEXP     ("Regexp"),
    NIL        ("NilClass");

    private final String rubyName;

    private RubyType(String rubyName)
    {
        this.rubyName = rubyName;
    }

    public String getRubyName() {
        return rubyName;
    }

    @Override
    public String toString() {
        return rubyName;
    }

    private static final Map<String, RubyType> TABLE;
    static {
        TABLE = new HashMap<String, RubyType>();
        for (RubyType t : RubyType.values()) {
            TABLE.put(t.rubyName.toLowerCase(), t);
        }
    }

    public static RubyType getRubyType(String rubyName) {
        return TABLE.get(rubyName.toLowerCase());
    }

    public static RubyType jdbcTypeToRubyType(int type, int scale) {
        RubyType primitiveType;
        switch (type) {
        case Types.INTEGER:
        case Types.SMALLINT:
        case Types.TINYINT:
            primitiveType = RubyType.FIXNUM;
            break;
        case Types.BIGINT:
            primitiveType = RubyType.BIGNUM;
            break;
        case Types.BIT:
        case Types.BOOLEAN:
            primitiveType = RubyType.TRUE_CLASS;
            break;
        case Types.CHAR:
        case Types.VARCHAR:
            primitiveType = RubyType.STRING;
            break;
        case Types.DATE:
            primitiveType = RubyType.DATE;
            break;
        case Types.TIMESTAMP:
            primitiveType = RubyType.DATE_TIME;
            break;
        case Types.TIME:
            primitiveType = RubyType.TIME;
            break;
        case Types.DECIMAL:
        case Types.NUMERIC:
            primitiveType = RubyType.BIG_DECIMAL;
            break;
        case Types.REAL:
        case Types.FLOAT:
        case Types.DOUBLE:
            primitiveType = RubyType.FLOAT;
            break;
        case Types.BLOB:
        case Types.JAVA_OBJECT: // XXX: Not sure this should be here
        case Types.VARBINARY:
        case Types.BINARY:
        case Types.LONGVARBINARY:
            primitiveType = RubyType.BYTE_ARRAY;
            break;
        case Types.NULL:
            primitiveType = RubyType.NIL;
            break;
        default:
            primitiveType = RubyType.STRING;
        }
        return primitiveType;
    }

    public static RubyType inferRubyType(IRubyObject obj){
        RubyType primitiveType = null;
        Ruby runtime = obj.getRuntime();

        //XXX Remember that types must by correctly ordered
        // RubyObject must be last, Extlib::ByteArray must be before String, etc (inheritance)
        if(obj instanceof RubyFixnum){
            primitiveType = RubyType.FIXNUM;
        }else if(obj instanceof RubyBignum){
            primitiveType = RubyType.BIGNUM;
        }else if(obj instanceof RubyInteger){
            primitiveType = RubyType.INTEGER;
        }else if(obj instanceof RubyFloat){
            primitiveType = RubyType.FLOAT;
        }else if(obj instanceof RubyBigDecimal){
            primitiveType = RubyType.BIG_DECIMAL;
        }else if(obj.getMetaClass().hasModuleInHierarchy(runtime.fastGetModule("Extlib").fastGetClass("ByteArray"))){
            primitiveType = RubyType.BYTE_ARRAY;
        }else if(obj instanceof RubyString){
            primitiveType = RubyType.STRING;
        }else if(obj instanceof RubyTime){
            primitiveType = RubyType.TIME;
        }else if(obj.getMetaClass().hasModuleInHierarchy(runtime.fastGetClass("DateTime"))){
            primitiveType = RubyType.DATE_TIME;
        }else if(obj.getMetaClass().hasModuleInHierarchy(runtime.fastGetClass("Date"))){
            primitiveType = RubyType.DATE;
        }else if(obj instanceof RubyNil){
            primitiveType = RubyType.NIL;
        }else if(obj.getMetaClass().hasModuleInHierarchy(runtime.fastGetClass("TrueClass"))){
            primitiveType = RubyType.TRUE_CLASS;
        }else if(obj.getMetaClass().hasModuleInHierarchy(runtime.fastGetClass("FalseClass"))){
            primitiveType = RubyType.FALSE_CLASS;
        }else if(obj instanceof RubyRational){
            primitiveType = RubyType.RATIONAL;
        }else if(obj instanceof RubyRegexp){
            primitiveType = RubyType.REGEXP;
        }else if(obj instanceof RubyClass){
            primitiveType = RubyType.CLASS;
        }else{
            primitiveType = RubyType.OBJECT;
        }
        return primitiveType;
    }
}
