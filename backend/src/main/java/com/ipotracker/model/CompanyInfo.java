package com.ipotracker.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Entity
@Table(name = "company_info")
@Getter
@Setter
public class CompanyInfo {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "ipo_id", nullable = false, unique = true)
    private UUID ipoId;

    @Column(columnDefinition = "text") private String description;
    @Column(columnDefinition = "text") private String promoters;
    @Column(name = "lead_managers", columnDefinition = "text") private String leadManagers;
    @Column(columnDefinition = "text") private String objectives;
    @Column(name = "website_url") private String websiteUrl;
}
