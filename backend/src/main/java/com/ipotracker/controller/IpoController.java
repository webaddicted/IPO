package com.ipotracker.controller;

import com.ipotracker.dto.Dtos;
import com.ipotracker.model.GmpData;
import com.ipotracker.model.IpoKind;
import com.ipotracker.model.SubscriptionData;
import com.ipotracker.service.GmpScraperService;
import com.ipotracker.service.IpoScraperService;
import com.ipotracker.service.IpoService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class IpoController {

    private final IpoService ipoService;
    private final IpoScraperService ipoScraper;
    private final GmpScraperService gmpScraper;

    public IpoController(IpoService ipoService, IpoScraperService ipoScraper, GmpScraperService gmpScraper) {
        this.ipoService = ipoService;
        this.ipoScraper = ipoScraper;
        this.gmpScraper = gmpScraper;
    }

    @GetMapping("/ipos/current")
    public List<Dtos.IpoSummary> current(@RequestParam(defaultValue = "mainline") IpoKind type) {
        return ipoService.current(type);
    }

    @GetMapping("/ipos/listed")
    public List<Dtos.IpoSummary> listed(@RequestParam(defaultValue = "mainline") IpoKind type) {
        return ipoService.listed(type);
    }

    @GetMapping("/ipos/{id}")
    public Dtos.IpoDetail detail(@PathVariable UUID id) {
        return ipoService.detail(id);
    }

    @GetMapping("/ipos/{id}/gmp")
    public List<GmpData> gmp(@PathVariable UUID id) {
        return ipoService.gmpHistory(id);
    }

    @GetMapping("/ipos/{id}/subscription")
    public List<SubscriptionData> subscription(@PathVariable UUID id) {
        return ipoService.subscriptions(id);
    }

    // ---- Manual scrape triggers (handy for ops / cron-less environments) ----

    @PostMapping("/admin/scrape/list")
    public Map<String, Object> triggerListScrape() {
        return Map.of("upserted", ipoScraper.scrapeAndStoreAll());
    }

    @PostMapping("/admin/scrape/gmp")
    public Map<String, Object> triggerGmpScrape() {
        return Map.of("updated", gmpScraper.refreshActiveGmp());
    }

    @PostMapping("/admin/scrape/detail/{slug}")
    public ResponseEntity<?> triggerDetailScrape(@PathVariable String slug) {
        return ipoScraper.scrapeDetail(slug)
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
