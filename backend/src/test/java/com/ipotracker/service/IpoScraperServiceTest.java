package com.ipotracker.service;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for the pure parsing helpers, anchored on the real shape of
 * chittorgarh's data-read JSON (verified against live responses).
 */
class IpoScraperServiceTest {

    private final IpoScraperService svc = new IpoScraperService(null);

    @Test
    void buildUrlTargetsReport82WithStringParameter() {
        String url = svc.buildUrl("mainboard");
        assertTrue(url.contains("/cloud/report/data-read/82/1/"), url);
        assertTrue(url.endsWith("/mainboard?search=&v=1"), url);
        assertTrue(url.contains("/" + LocalDate.now().getYear() + "/"), url);
    }

    @Test
    void detailUrlExtractsNumericIdFromCompanyAnchor() {
        String html = "<a href=\"https://www.chittorgarh.com/ipo/aastha-spintex-ipo/2678/\" "
                + "title=\"Aastha Spintex IPO Details\">Aastha Spintex Ltd.</a>";
        assertEquals("https://www.chittorgarh.com/ipo/aastha-spintex-ipo/2678/",
                IpoScraperService.detailUrl(html, "aastha-spintex-ipo"));
    }

    @Test
    void detailUrlFallsBackWithoutId() {
        assertEquals("https://www.chittorgarh.com/ipo/foo-ipo/",
                IpoScraperService.detailUrl("no anchor here", "foo-ipo"));
    }

    @Test
    void stripHtmlPullsPlainText() {
        assertEquals("Aastha Spintex Ltd.",
                IpoScraperService.stripHtml("<a href=\"x\">Aastha Spintex Ltd.</a> "));
    }

    @Test
    void isoDateConvertsInstantToIstDate() {
        // 18:28 UTC is 23:58 IST — still the same calendar day.
        assertEquals(LocalDate.of(2026, 9, 24),
                IpoScraperService.isoDate("2026-09-24T18:28:39.000Z"));
        // Midnight UTC -> 05:30 IST, same day.
        assertEquals(LocalDate.of(2026, 6, 23),
                IpoScraperService.isoDate("2026-06-23T00:00:00.000Z"));
        assertNull(IpoScraperService.isoDate(""));
        assertNull(IpoScraperService.isoDate(null));
    }
}
