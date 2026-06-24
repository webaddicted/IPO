package com.ipotracker.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "subscription_data")
@Getter
@Setter
public class SubscriptionData {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "ipo_id", nullable = false)
    private UUID ipoId;

    /** 'overall' for headline, or 'day1' / 'day2' / 'day3'. */
    @Column(nullable = false)
    private String bucket = "overall";

    @Column(name = "total_subscription")    private BigDecimal totalSubscription;
    @Column(name = "qib_subscription")      private BigDecimal qibSubscription;
    @Column(name = "nii_subscription")      private BigDecimal niiSubscription;
    @Column(name = "bnii_subscription")     private BigDecimal bniiSubscription;
    @Column(name = "snii_subscription")     private BigDecimal sniiSubscription;
    @Column(name = "retail_subscription")   private BigDecimal retailSubscription;
    @Column(name = "employee_subscription") private BigDecimal employeeSubscription;
    @Column(name = "total_applications")    private Long totalApplications;
}
