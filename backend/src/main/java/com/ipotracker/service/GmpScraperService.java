package com.ipotracker.service;

import com.ipotracker.model.GmpData;
import com.ipotracker.model.Ipo;
import com.ipotracker.model.IpoStatus;
import com.ipotracker.repository.GmpRepository;
import com.ipotracker.repository.IpoRepository;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

/**
 * Records a grey-market-premium snapshot per active IPO. GMP is published on
 * pages like investorgain.com / chittorgarh GMP report; here we read the IPO's
 * own detail page GMP block as a single source. Each run appends one row to
 * gmp_data (time series) and refreshes the denormalised headline on ipos.
 */
@Service
public class GmpScraperService {

    private static final Logger log = LoggerFactory.getLogger(GmpScraperService.class);

    private final IpoRepository ipoRepo;
    private final GmpRepository gmpRepo;

    @Value("${scraper.user-agent}") private String userAgent;
    @Value("${scraper.timeout-ms}") private int timeoutMs;

    public GmpScraperService(IpoRepository ipoRepo, GmpRepository gmpRepo) {
        this.ipoRepo = ipoRepo;
        this.gmpRepo = gmpRepo;
    }

    /** Refresh GMP for every IPO that is still open or upcoming. */
    @Transactional
    public int refreshActiveGmp() {
        List<Ipo> active = ipoRepo.findAll().stream()
                .filter(i -> i.getStatus() == IpoStatus.open || i.getStatus() == IpoStatus.upcoming)
                .toList();
        int updated = 0;
        for (Ipo ipo : active) {
            BigDecimal gmp = scrapeGmpValue(ipo);
            if (gmp != null) {
                record(ipo, gmp);
                updated++;
            }
        }
        log.info("Refreshed GMP for {}/{} active IPOs", updated, active.size());
        return updated;
    }

    private BigDecimal scrapeGmpValue(Ipo ipo) {
        if (ipo.getSourceUrl() == null) return null;
        try {
            Document doc = Jsoup.connect(ipo.getSourceUrl())
                    .userAgent(userAgent).timeout(timeoutMs).get();
            // Look for a cell whose label mentions GMP and read its sibling value.
            for (Element row : doc.select("table tr")) {
                if (row.text().toLowerCase().contains("gmp") && row.select("td").size() >= 2) {
                    return ParseUtil.money(row.select("td").get(1).text());
                }
            }
        } catch (Exception e) {
            log.debug("No GMP for {}: {}", ipo.getSourceSlug(), e.getMessage());
        }
        return null;
    }

    private void record(Ipo ipo, BigDecimal gmp) {
        GmpData g = new GmpData();
        g.setIpoId(ipo.getId());
        g.setGmpPrice(gmp);

        BigDecimal base = ipo.getIssuePrice() != null ? ipo.getIssuePrice() : ipo.getOfferPriceMax();
        if (base != null && base.signum() > 0) {
            BigDecimal pct = gmp.multiply(BigDecimal.valueOf(100)).divide(base, 2, RoundingMode.HALF_UP);
            g.setGmpPercent(pct);
            g.setEstimatedListingPrice(base.add(gmp));
            ipo.setLatestGmpPercent(pct);
        }
        gmpRepo.save(g);

        ipo.setLatestGmp(gmp);
        ipoRepo.save(ipo);
    }
}
