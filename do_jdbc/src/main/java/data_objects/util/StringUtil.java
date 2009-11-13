package data_objects.util;

import java.util.List;

/**
 *
 * @author alexbcoles
 */
public final class StringUtil {

    public static String join(List<?> list, CharSequence delim) {
        StringBuilder sb = new StringBuilder();
        return appendJoined(sb, list, delim).toString();
    }

    public static StringBuilder appendJoined(StringBuilder sb,
            List<?> list) {
        return appendJoined(sb, list, ",", false);
    }

    public static StringBuilder appendJoined(StringBuilder sb,
            List<?> list, CharSequence delim) {
        return appendJoined(sb, list, delim, false);
    }

    public static StringBuilder appendJoinedAndQuoted(StringBuilder sb,
            List<?> list) {
        return appendJoined(sb, list, ",", true);
    }

    public static StringBuilder appendJoinedAndQuoted(StringBuilder sb,
            List<?> list, CharSequence delim) {
        return appendJoined(sb, list, delim, true);
    }

    public static StringBuilder appendQuoted(StringBuilder sb, Object toQuote) {
        sb.append("\"").append(toQuote).append("\"");
        return sb;
    }

    private static StringBuilder appendJoined(StringBuilder sb,
            List<?> list, CharSequence delim, boolean quote) {
        if (list.isEmpty()) {
            return sb.append("");
        }

        if (quote) {
            appendQuoted(sb, list.get(0));
        } else {
            sb.append(list.get(0));
        }
        for (int i = 1; i < list.size(); i++) {
            sb.append(delim);
            if (quote) {
                appendQuoted(sb, list.get(i));
            } else {
                sb.append(list.get(i));
            }
        }
        return sb;
    }

    /**
     * Private constructor
     */
    private StringUtil(){
    }

}
