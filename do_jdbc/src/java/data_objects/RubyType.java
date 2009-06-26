package data_objects;

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

}
