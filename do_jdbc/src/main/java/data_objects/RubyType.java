package data_objects;

import java.sql.Types;
import java.util.HashMap;
import java.util.Map;
import org.jruby.RubyClass;
import org.jruby.runtime.builtin.IRubyObject;

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
    NIL        ("NilClass"),
    OTHER      ("#OTHER#");

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

    public static RubyType inferRubyType(IRubyObject arg) {
        return getRubyType(arg.getType());
    }

    public static RubyType getRubyType(RubyClass rubyClass) {
        RubyType result = TABLE.get(rubyClass.getName().toLowerCase());
        if(result == null){
            rubyClass = rubyClass.getSuperClass();
            if(rubyClass.getName().equals("Object")){
                return OTHER;
            }
            else {
                return getRubyType(rubyClass);
            }
        }
        else{
          return result;
        }
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

}
