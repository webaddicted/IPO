package com.ipotracker.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "ipo_reservation")
@Getter
@Setter
public class IpoReservation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "ipo_id", nullable = false)
    private UUID ipoId;

    private String category;   // QIB, NII, Retail, Employee, Market Maker
    @Column(name = "shares_offered")   private Long sharesOffered;
    @Column(name = "percent_of_total") private BigDecimal percentOfTotal;
}
