package com.ipotracker.dto;

import com.ipotracker.model.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** API response shapes. Records keep the JSON contract explicit and decoupled
 *  from the JPA entities. */
public final class Dtos {

    private Dtos() {}

    public record IpoSummary(
            UUID id, String sourceSlug, String companyName, String logoUrl,
            String ipoType, String status,
            BigDecimal offerPriceMin, BigDecimal offerPriceMax, Integer lotSize,
            LocalDate openDate, LocalDate closeDate, LocalDate listingDate,
            String listingAt,
            BigDecimal latestGmp, BigDecimal latestGmpPercent, BigDecimal latestSubscription
    ) {
        public static IpoSummary from(Ipo i) {
            return new IpoSummary(
                    i.getId(), i.getSourceSlug(), i.getCompanyName(), i.getLogoUrl(),
                    i.getIpoType().name(), i.getStatus().name(),
                    i.getOfferPriceMin(), i.getOfferPriceMax(), i.getLotSize(),
                    i.getOpenDate(), i.getCloseDate(), i.getListingDate(),
                    i.getListingAt(),
                    i.getLatestGmp(), i.getLatestGmpPercent(), i.getLatestSubscription());
        }
    }

    public record IpoDetail(
            Ipo ipo,
            List<GmpData> gmp,
            List<SubscriptionData> subscriptions,
            List<FinancialData> financials,
            List<KpiData> kpis,
            List<IpoReservation> reservations,
            List<LotSizeTier> lotSizes,
            List<ImportantDate> importantDates,
            CompanyInfo company
    ) {}
}
