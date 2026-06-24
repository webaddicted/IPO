package com.ipotracker.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "lot_size_tier")
@Getter
@Setter
public class LotSizeTier {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "ipo_id", nullable = false)
    private UUID ipoId;

    private String applicant;   // 'Retail (Min)', 'HNI (Min)' ...
    private Integer lots;
    private Long shares;
    private BigDecimal amount;
}
