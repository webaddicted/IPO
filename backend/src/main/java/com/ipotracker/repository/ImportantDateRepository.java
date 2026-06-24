package com.ipotracker.repository;

import com.ipotracker.model.ImportantDate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ImportantDateRepository extends JpaRepository<ImportantDate, UUID> {
    List<ImportantDate> findByIpoIdOrderBySortOrderAsc(UUID ipoId);
}
