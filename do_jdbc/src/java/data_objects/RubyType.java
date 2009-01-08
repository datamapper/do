package data_objects;

/**
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
    FIXNUM     ("Fixnum"),
    INTEGER    ("Integer"),
    BIGNUM     ("Bignum"),
    FLOAT      ("Float"),
    BIG_DECIMAL("BigDecimal");

    private String rubyName;

    RubyType(String rubyName)
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

    public static RubyType getRubyType(String rubyName) {
        RubyType type = null;
        for (RubyType t : RubyType.values()) {
            if (t.rubyName.equalsIgnoreCase(rubyName)) {
                type = t;
            }
        }
        return type;
    }

}
