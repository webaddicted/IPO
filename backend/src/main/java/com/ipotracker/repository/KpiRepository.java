package com.ipotracker.repository;

import com.ipotracker.model.KpiData;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface KpiRepository extends JpaRepository<KpiData, UUID> {
    List<KpiData> findByIpoId(UUID ipoId);
}
