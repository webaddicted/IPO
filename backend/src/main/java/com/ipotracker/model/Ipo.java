package com.ipotracker.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "ipos")
@Getter
@Setter
public class Ipo {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "source_slug", nullable = false, unique = true)
    private String sourceSlug;

    @Column(name = "company_name", nullable = false)
    private String companyName;

    @Column(name = "logo_url")
    private String logoUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "ipo_type", nullable = false)
    private IpoKind ipoType = IpoKind.mainline;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private IpoStatus status = IpoStatus.upcoming;

    // Pricing
    @Column(name = "offer_price_min") private BigDecimal offerPriceMin;
    @Column(name = "offer_price_max") private BigDecimal offerPriceMax;
    @Column(name = "issue_price")     private BigDecimal issuePrice;
    @Column(name = "face_value")      private BigDecimal faceValue;
    @Column(name = "lot_size")        private Integer lotSize;
    @Column(name = "min_investment")  private BigDecimal minInvestment;

    // Dates
    @Column(name = "open_date")           private LocalDate openDate;
    @Column(name = "close_date")          private LocalDate closeDate;
    @Column(name = "allotment_date")      private LocalDate allotmentDate;
    @Column(name = "refund_date")         private LocalDate refundDate;
    @Column(name = "demat_transfer_date") private LocalDate dematTransferDate;
    @Column(name = "listing_date")        private LocalDate listingDate;

    // Issue meta
    @Column(name = "listing_at")              private String listingAt;
    @Column(name = "issue_type")              private String issueType;
    @Column(name = "sale_type")               private String saleType;
    @Column(name = "total_issue_size_shares") private Long totalIssueSizeShares;
    @Column(name = "total_issue_size_amount") private BigDecimal totalIssueSizeAmount;
    @Column(name = "fresh_issue_shares")      private Long freshIssueShares;
    @Column(name = "ofs_shares")              private Long ofsShares;
    @Column(name = "market_maker_shares")     private Long marketMakerShares;

    // Denormalised headline numbers
    @Column(name = "latest_gmp")           private BigDecimal latestGmp;
    @Column(name = "latest_gmp_percent")   private BigDecimal latestGmpPercent;
    @Column(name = "latest_subscription")  private BigDecimal latestSubscription;

    @Column(name = "registrar")  private String registrar;
    @Column(name = "source_url") private String sourceUrl;

    @Column(name = "created_at", insertable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", insertable = false, updatable = false)
    private Instant updatedAt;
}
