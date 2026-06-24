package com.ipotracker.service;

import com.ipotracker.dto.AllotmentDtos.AllotmentRequest;
import com.ipotracker.dto.AllotmentDtos.AllotmentResult;
import com.ipotracker.dto.AllotmentDtos.Outcome;
import com.ipotracker.model.Ipo;
import com.ipotracker.model.RegistrarPortal;
import com.ipotracker.repository.IpoRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

/**
 * Resolves an IPO's registrar and checks allotment status for a PAN.
 *
 * Registrar portals (Bigshare, Link Intime, KFinTech, …) are captcha-protected
 * SPAs, so an unattended server-side lookup is not reliable. The service is
 * built around a per-registrar {@code attempt} hook: when a portal can be
 * queried it returns a concrete result, otherwise we degrade to a
 * MANUAL_CHECK_REQUIRED result carrying the official deep link. This keeps the
 * API contract stable while leaving room to plug in a headless-browser /
 * captcha-solving strategy per registrar later.
 */
@Service
public class AllotmentService {

    private static final Logger log = LoggerFactory.getLogger(AllotmentService.class);

    private final IpoRepository ipoRepo;

    public AllotmentService(IpoRepository ipoRepo) {
        this.ipoRepo = ipoRepo;
    }

    public AllotmentResult check(AllotmentRequest req) {
        Ipo ipo = resolve(req.ipoId());
        if (ipo == null) {
            return new AllotmentResult(Outcome.NOT_FOUND, null, null, null, null, null,
                    "IPO not found for id/slug: " + req.ipoId());
        }

        RegistrarPortal portal = RegistrarPortal.fromName(ipo.getRegistrar());
        String company = ipo.getCompanyName();

        try {
            Optional<AllotmentResult> result = attempt(portal, ipo, req);
            if (result.isPresent()) return result.get();
        } catch (Exception e) {
            log.warn("Allotment lookup failed for {} via {}: {}",
                    company, portal, e.getMessage());
        }

        // Fallback: hand the user the official portal to check manually.
        String url = portal.statusUrl();
        if (url == null) {
            return new AllotmentResult(Outcome.ERROR, company, portal.displayName(), null,
                    null, null, "No known allotment portal for this registrar.");
        }
        return AllotmentResult.manual(company, portal.displayName(), url);
    }

    /** Resolve by UUID first, then fall back to the source slug. */
    private Ipo resolve(String idOrSlug) {
        try {
            return ipoRepo.findById(UUID.fromString(idOrSlug)).orElse(null);
        } catch (IllegalArgumentException notUuid) {
            return ipoRepo.findBySourceSlug(idOrSlug).orElse(null);
        }
    }

    /**
     * Per-registrar automated lookup. Returns empty when no reliable automated
     * path exists (→ caller falls back to a manual deep link).
     *
     * Plug a real implementation in here (e.g. a captcha-aware headless flow)
     * per {@link RegistrarPortal} as it becomes available.
     */
    private Optional<AllotmentResult> attempt(RegistrarPortal portal, Ipo ipo, AllotmentRequest req) {
        // No registrar currently offers an unauthenticated, captcha-free endpoint
        // we can rely on, so all paths defer to the manual portal for now.
        return Optional.empty();
    }
}
