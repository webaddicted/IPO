package com.ipotracker.scheduler;

import com.ipotracker.service.GmpScraperService;
import com.ipotracker.service.IpoScraperService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/** Drives the scrapers on a schedule. Disable entirely with scraper.enabled=false. */
@Component
public class IpoScheduler {

    private static final Logger log = LoggerFactory.getLogger(IpoScheduler.class);

    private final IpoScraperService ipoScraper;
    private final GmpScraperService gmpScraper;

    @Value("${scraper.enabled}") private boolean enabled;

    public IpoScheduler(IpoScraperService ipoScraper, GmpScraperService gmpScraper) {
        this.ipoScraper = ipoScraper;
        this.gmpScraper = gmpScraper;
    }

    /** Full IPO list refresh — hourly (configurable via scraper.list-fixed-rate-ms). */
    @Scheduled(fixedRateString = "${scraper.list-fixed-rate-ms}", initialDelay = 15000)
    public void refreshIpoList() {
        if (!enabled) return;
        try {
            int n = ipoScraper.scrapeAndStoreAll();
            log.info("IPO list refresh complete: {} rows upserted", n);
        } catch (Exception e) {
            log.error("IPO list refresh failed", e);
        }
    }

    /** GMP refresh every 30 minutes during Indian market hours, Mon–Fri. */
    @Scheduled(cron = "0 */30 9-16 * * MON-FRI", zone = "Asia/Kolkata")
    public void refreshGmp() {
        if (!enabled) return;
        try {
            gmpScraper.refreshActiveGmp();
        } catch (Exception e) {
            log.error("GMP refresh failed", e);
        }
    }
}
