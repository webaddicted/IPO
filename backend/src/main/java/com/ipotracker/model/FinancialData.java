package com.ipotracker.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "financial_data")
@Getter
@Setter
public class FinancialData {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "ipo_id", nullable = false)
    private UUID ipoId;

    private String period;

    private BigDecimal revenue;
    @Column(name = "profit_after_tax") private BigDecimal profitAfterTax;
    @Column(name = "total_assets")     private BigDecimal totalAssets;
    @Column(name = "net_worth")        private BigDecimal netWorth;
    @Column(name = "total_borrowing")  private BigDecimal totalBorrowing;
}
