package com.ipotracker.model;

import java.util.Locale;

/**
 * Known IPO registrars and their public allotment-status portals.
 *
 * Registrar allotment pages are almost always captcha-protected SPAs, so a
 * pure server-side scrape cannot be guaranteed. Each portal therefore also
 * exposes a deep link the user can open to check manually.
 */
public enum RegistrarPortal {
    BIGSHARE("Bigshare Services",
            "https://ipo.bigshareonline.com/ipo_Allotment.html"),
    LINKINTIME("Link Intime India",
            "https://linkintime.co.in/initial_offer/public-issues.html"),
    KFINTECH("KFin Technologies",
            "https://ris.kfintech.com/ipostatus/"),
    MAASHITLA("Maashitla Securities",
            "https://www.maashitla.com/allotment-status/public-issues"),
    CAMEO("Cameo Corporate Services",
            "https://ipo.cameoindia.com/"),
    UNKNOWN("Registrar", null);

    private final String displayName;
    private final String statusUrl;

    RegistrarPortal(String displayName, String statusUrl) {
        this.displayName = displayName;
        this.statusUrl = statusUrl;
    }

    public String displayName() { return displayName; }

    public String statusUrl() { return statusUrl; }

    /** Best-effort match of a free-text registrar name to a known portal. */
    public static RegistrarPortal fromName(String name) {
        if (name == null) return UNKNOWN;
        String n = name.toLowerCase(Locale.ROOT);
        if (n.contains("bigshare")) return BIGSHARE;
        if (n.contains("link") && n.contains("intime")) return LINKINTIME;
        if (n.contains("kfin") || n.contains("karvy")) return KFINTECH;
        if (n.contains("maashitla")) return MAASHITLA;
        if (n.contains("cameo")) return CAMEO;
        return UNKNOWN;
    }
}
