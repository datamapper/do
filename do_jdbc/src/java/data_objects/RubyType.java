package data_objects;

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
    NIL        ("NilClass");

    private String rubyName;

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

    private static final Map<String, RubyType> table;
    static {
        table = new HashMap<String, RubyType>();
        for (RubyType t : RubyType.values()) {
            table.put(t.rubyName.toLowerCase(), t);
        }
    }
    
    public static RubyType getRubyType(String rubyName) {
        return table.get(rubyName.toLowerCase());
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
        // No casting rule for type #{meta_data.column_type(i)}
        // (#{meta_data.column_name(i)}). Please report this."
        return primitiveType;
    }

}
