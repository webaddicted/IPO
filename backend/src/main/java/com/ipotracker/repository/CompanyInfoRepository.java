package com.ipotracker.repository;

import com.ipotracker.model.CompanyInfo;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface CompanyInfoRepository extends JpaRepository<CompanyInfo, UUID> {
    Optional<CompanyInfo> findByIpoId(UUID ipoId);
}
