package junit.framework;

public abstract class TestCase {
    public static void assertTrue(String message, boolean condition) {
        if (!condition) throw new AssertionError(message);
    }

    public static void assertEquals(Object expected, Object actual) {
        if (expected == null ? actual != null : !expected.equals(actual)) {
            throw new AssertionError("expected=" + expected + " actual=" + actual);
        }
    }
}
