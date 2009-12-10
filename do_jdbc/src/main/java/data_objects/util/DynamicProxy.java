package data_objects.util;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.Arrays;

/**
 * @author Piotr Gega (pietia)
 */
public class DynamicProxy implements InvocationHandler {

    private final Object PROXIED_OBJECT;
    private final static String OUTPUT_FORMAT;

    static {
        OUTPUT_FORMAT = "DO_ %8dns [%-9s, %-70s, %s ]";
    }

    DynamicProxy(Object proxiedObject) {
        this.PROXIED_OBJECT = proxiedObject;
    }

    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        Object res = null;
        long timeStart = System.nanoTime();
        try {
            res = method.invoke(PROXIED_OBJECT, args);
            tryToLog(proxy, timeStart,  method, args);
        } catch (InvocationTargetException ex) {
            tryToLog(proxy, timeStart,  method, args);
            throw ex.getCause();
        } catch (IllegalAccessException ex) {
            tryToLog(proxy, timeStart, method, args);
            throw ex.getCause();
        }
        return res;
    }

    private void tryToLog(Object proxy, long timeStart, Method method, Object[] args) {
        //if logger is on
        if (DynamicProxyUtil.LOGGER_ON) {
            long timeStop = System.nanoTime();
            System.out.println(String.format(OUTPUT_FORMAT, timeStop - timeStart, proxy.getClass().getName(),
            PROXIED_OBJECT.getClass().getName() + "#" + method.getName(), Arrays.toString(args).replaceAll("\n","").trim()));
        }
    }


}
