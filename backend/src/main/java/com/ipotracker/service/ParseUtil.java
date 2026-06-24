package com.ipotracker.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Defensive text → typed-value helpers for scraped HTML. All methods return
 *  null on anything they can't confidently parse — never throw. */
public final class ParseUtil {

    private ParseUtil() {}

    private static final Pattern NUMBER = Pattern.compile("-?[0-9][0-9,]*\\.?[0-9]*");

    // Chittorgarh renders dates like "Jun 4, 2026", "4 Jun 2026", "Thu, Jun 11, 2026".
    private static final DateTimeFormatter[] DATE_FORMATS = {
            DateTimeFormatter.ofPattern("MMM d, yyyy", Locale.ENGLISH),
            DateTimeFormatter.ofPattern("d MMM yyyy", Locale.ENGLISH),
            DateTimeFormatter.ofPattern("EEE, MMM d, yyyy", Locale.ENGLISH),
            DateTimeFormatter.ofPattern("dd-MM-yyyy", Locale.ENGLISH),
            DateTimeFormatter.ofPattern("yyyy-MM-dd", Locale.ENGLISH),
    };

    /** First numeric token in the string, commas stripped. e.g. "₹1,234.50/-" -> 1234.50 */
    public static BigDecimal money(String s) {
        if (s == null) return null;
        Matcher m = NUMBER.matcher(s.replace(",", ""));
        if (m.find()) {
            try { return new BigDecimal(m.group()); } catch (NumberFormatException ignored) {}
        }
        return null;
    }

    public static Integer integer(String s) {
        BigDecimal b = money(s);
        return b == null ? null : b.intValue();
    }

    public static Long longVal(String s) {
        BigDecimal b = money(s);
        return b == null ? null : b.longValue();
    }

    /** Parses a price band like "₹157 to ₹166" -> [157, 166]. Single price -> both equal. */
    public static BigDecimal[] priceBand(String s) {
        if (s == null) return new BigDecimal[]{null, null};
        String cleaned = s.replace(",", "");
        Matcher m = NUMBER.matcher(cleaned);
        BigDecimal lo = null, hi = null;
        if (m.find()) lo = parse(m.group());
        if (m.find()) hi = parse(m.group());
        if (hi == null) hi = lo;
        return new BigDecimal[]{lo, hi};
    }

    /** Tries each known format; returns the first date that parses, or the first
     *  date found anywhere in the string. */
    public static LocalDate date(String s) {
        if (s == null || s.isBlank()) return null;
        String t = s.trim();
        for (DateTimeFormatter f : DATE_FORMATS) {
            try { return LocalDate.parse(t, f); } catch (Exception ignored) {}
        }
        // Fallback: try to locate a "Mon d, yyyy" substring inside a longer label.
        Matcher m = Pattern.compile("[A-Za-z]{3,}\\.?\\s+\\d{1,2},?\\s+\\d{4}").matcher(t);
        if (m.find()) {
            for (DateTimeFormatter f : DATE_FORMATS) {
                try { return LocalDate.parse(m.group().replace(".", ""), f); } catch (Exception ignored) {}
            }
        }
        return null;
    }

    /** Slug from a chittorgarh URL: ".../ipo/uhm-vacation-ipo/" -> "uhm-vacation-ipo". */
    public static String slugFromUrl(String url) {
        if (url == null || url.isBlank()) return null;
        String[] parts = url.replaceAll("/+$", "").split("/");
        return parts.length == 0 ? null : parts[parts.length - 1];
    }

    private static BigDecimal parse(String s) {
        try { return new BigDecimal(s); } catch (NumberFormatException e) { return null; }
    }
}
