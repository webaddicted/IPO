package com.ipotracker.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ipotracker.model.Ipo;
import com.ipotracker.model.IpoKind;
import com.ipotracker.model.IpoStatus;
import com.ipotracker.repository.IpoRepository;
import org.jsoup.Jsoup;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Pulls Indian IPO data from chittorgarh.com.
 *
 * chittorgarh is a Next.js single-page app: the list pages contain NO
 * server-rendered table, so HTML/CSS scraping does not work. Instead the site's
 * React client reads a JSON report API, which this service targets directly —
 * far more robust than HTML scraping:
 *
 *   GET https://webnodejs.chittorgarh.com/cloud/report/data-read/
 *       {reportId}/{page}/{month}/{year}/{financialYear}/{sort}/{parameter}
 *
 * For the "IPO in India" report, reportId = 82 and {parameter} is the string
 * code "mainboard", "sme" or "all" (NOT a numeric id — that was the trap).
 *
 * ⚠️ Review chittorgarh's Terms of Service before running in production and
 *    keep the polite delay between calls.
 */
@Service
public class IpoScraperService {

    private static final Logger log = LoggerFactory.getLogger(IpoScraperService.class);

    private static final String DATA_API =
            "https://webnodejs.chittorgarh.com/cloud/report/data-read";
    private static final int REPORT_ID = 82;            // "IPO in India" report
    private static final String SITE = "https://www.chittorgarh.com";

    // Each IPO's anchor looks like /ipo/<slug>/<numericId>/
    private static final Pattern IPO_ID = Pattern.compile("/ipo/[^/]+/(\\d+)/");

    private final IpoRepository ipoRepo;
    private final ObjectMapper mapper = new ObjectMapper();

    @Value("${scraper.user-agent}")      private String userAgent;
    @Value("${scraper.timeout-ms}")      private int timeoutMs;
    @Value("${scraper.polite-delay-ms}") private long politeDelayMs;

    public IpoScraperService(IpoRepository ipoRepo) {
        this.ipoRepo = ipoRepo;
    }

    /** Scrape both mainline and SME lists; returns rows upserted. */
    @Transactional
    public int scrapeAndStoreAll() {
        int n = scrapeList("mainboard", IpoKind.mainline);
        sleepPolitely();
        n += scrapeList("sme", IpoKind.sme);
        return n;
    }

    int scrapeList(String parameter, IpoKind kind) {
        int count = 0;
        try {
            JsonNode root = mapper.readTree(fetchJson(buildUrl(parameter)));
            if (root.path("msg").asInt(-1) != 1) {
                log.warn("data-read returned msg!=1 for {}: {}", parameter,
                        root.path("error").asText());
                return 0;
            }
            JsonNode rows = root.path("reportTableData");
            log.info("Fetched {} {} IPO rows", rows.size(), parameter);

            for (JsonNode row : rows) {
                try {
                    Ipo ipo = parseRow(row, kind);
                    if (ipo != null) {
                        ipoRepo.save(ipo);
                        count++;
                    }
                } catch (Exception e) {
                    log.warn("Skipping unparseable row: {}", e.getMessage());
                }
            }
        } catch (IOException e) {
            log.error("Failed to fetch {} list: {}", parameter, e.getMessage());
        }
        return count;
    }

    String buildUrl(String parameter) {
        LocalDate now = LocalDate.now();
        int year = now.getYear();
        int month = now.getMonthValue();
        // Indian financial year: Apr–Mar. e.g. 2026-27 from Apr 2026.
        int fyStart = month >= 4 ? year : year - 1;
        String fy = fyStart + "-" + String.format("%02d", (fyStart + 1) % 100);
        return String.format("%s/%d/1/%d/%d/%s/0/%s?search=&v=1",
                DATA_API, REPORT_ID, month, year, fy, parameter);
    }

    /** Map one JSON report row to an Ipo, upserting by slug. */
    private Ipo parseRow(JsonNode row, IpoKind kind) {
        String slug = text(row, "~URLRewrite_Folder_Name");
        if (slug == null || slug.isBlank()) return null;

        Ipo ipo = ipoRepo.findBySourceSlug(slug).orElseGet(Ipo::new);
        ipo.setSourceSlug(slug);
        ipo.setIpoType(kind);

        String name = text(row, "~IPO");
        ipo.setCompanyName(name != null ? name : stripHtml(text(row, "Company")));

        // Build the canonical detail URL from the numeric id in the Company anchor.
        String companyHtml = text(row, "Company");
        ipo.setSourceUrl(detailUrl(companyHtml, slug));

        ipo.setLogoUrl(text(row, "~compare_image"));
        ipo.setListingAt(text(row, "Listing at"));

        String pricing = text(row, "Pricing Method");
        if (pricing != null && !pricing.isBlank()) {
            ipo.setIssueType(pricing.toLowerCase().contains("book")
                    ? "Bookbuilding IPO" : "Fixed Price IPO");
        }

        ipo.setIssuePrice(ParseUtil.money(text(row, "Issue Price (Rs.)")));

        // Total Issue Amount is in ₹ crore → store absolute INR.
        BigDecimal cr = ParseUtil.money(
                text(row, "Total Issue Amount (Incl.Firm reservations) (Rs.cr.)"));
        if (cr != null) ipo.setTotalIssueSizeAmount(cr.multiply(BigDecimal.valueOf(10_000_000)));

        ipo.setOpenDate(isoDate(text(row, "~Issue_Open_Date")));
        ipo.setCloseDate(isoDate(text(row, "~IssueCloseDate")));
        ipo.setListingDate(isoDate(text(row, "~ListingDate")));

        ipo.setStatus(deriveStatus(ipo));
        return ipo;
    }

    private IpoStatus deriveStatus(Ipo ipo) {
        LocalDate today = LocalDate.now();
        if (ipo.getListingDate() != null && !today.isBefore(ipo.getListingDate())) return IpoStatus.listed;
        if (ipo.getOpenDate() != null && ipo.getCloseDate() != null
                && !today.isBefore(ipo.getOpenDate()) && !today.isAfter(ipo.getCloseDate())) return IpoStatus.open;
        if (ipo.getOpenDate() != null && today.isBefore(ipo.getOpenDate())) return IpoStatus.upcoming;
        if (ipo.getCloseDate() != null && today.isAfter(ipo.getCloseDate())) return IpoStatus.closed;
        return ipo.getStatus() != null ? ipo.getStatus() : IpoStatus.upcoming;
    }

    /**
     * Detail enrichment hook. The detail page is also a Next.js SPA backed by a
     * per-IPO JSON report; wiring that report id is a follow-up. For now this
     * is a no-op that returns the stored row unchanged.
     */
    @Transactional
    public Optional<Ipo> scrapeDetail(String slug) {
        return ipoRepo.findBySourceSlug(slug);
    }

    // ---- helpers -------------------------------------------------------------

    private String fetchJson(String url) throws IOException {
        return Jsoup.connect(url)
                .ignoreContentType(true)        // it's JSON, not HTML
                .userAgent(userAgent)
                .header("Referer", SITE + "/")
                .header("Accept", "application/json")
                .timeout(timeoutMs)
                .maxBodySize(0)
                .execute()
                .body();
    }

    private static String text(JsonNode row, String field) {
        JsonNode n = row.get(field);
        if (n == null || n.isNull()) return null;
        String s = n.asText().trim();
        return s.isEmpty() ? null : s;
    }

    static String stripHtml(String html) {
        return html == null ? null : Jsoup.parse(html).text().trim();
    }

    static String detailUrl(String companyHtml, String slug) {
        if (companyHtml != null) {
            Matcher m = IPO_ID.matcher(companyHtml);
            if (m.find()) return SITE + "/ipo/" + slug + "/" + m.group(1) + "/";
        }
        return SITE + "/ipo/" + slug + "/";
    }

    /** Parse an ISO-8601 instant string ("2026-09-24T18:28:39.000Z") to an IST date. */
    static LocalDate isoDate(String s) {
        if (s == null || s.isBlank()) return null;
        try {
            return Instant.parse(s).atZone(ZoneId.of("Asia/Kolkata")).toLocalDate();
        } catch (Exception e) {
            return ParseUtil.date(s);
        }
    }

    private void sleepPolitely() {
        try { Thread.sleep(politeDelayMs); }
        catch (InterruptedException e) { Thread.currentThread().interrupt(); }
    }
}
