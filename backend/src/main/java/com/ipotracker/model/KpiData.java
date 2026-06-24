package com.ipotracker.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "kpi_data")
@Getter
@Setter
public class KpiData {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "ipo_id", nullable = false)
    private UUID ipoId;

    private String metric;   // ROE, ROCE, EPS, PE_POST, RONW, DEBT_EQUITY
    private BigDecimal value;
    private String unit;     // '%', 'x', 'INR'
}
