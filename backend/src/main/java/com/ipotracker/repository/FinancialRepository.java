package com.ipotracker.repository;

import com.ipotracker.model.FinancialData;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface FinancialRepository extends JpaRepository<FinancialData, UUID> {
    List<FinancialData> findByIpoIdOrderByPeriodDesc(UUID ipoId);
}
