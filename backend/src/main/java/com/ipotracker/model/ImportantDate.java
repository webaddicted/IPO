package com.ipotracker.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "important_dates")
@Getter
@Setter
public class ImportantDate {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "ipo_id", nullable = false)
    private UUID ipoId;

    private String event;   // 'IPO Open', 'Allotment', 'Listing' ...
    @Column(name = "event_date") private LocalDate eventDate;
    @Column(name = "sort_order") private Integer sortOrder = 0;
}
