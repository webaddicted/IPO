package com.ipotracker.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "gmp_data")
@Getter
@Setter
public class GmpData {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "ipo_id", nullable = false)
    private UUID ipoId;

    @Column(name = "gmp_price")               private BigDecimal gmpPrice;
    @Column(name = "gmp_percent")             private BigDecimal gmpPercent;
    @Column(name = "estimated_listing_price") private BigDecimal estimatedListingPrice;

    @Column(name = "recorded_at", insertable = false, updatable = false)
    private Instant recordedAt;
}
