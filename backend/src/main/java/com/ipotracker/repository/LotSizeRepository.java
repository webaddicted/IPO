package com.ipotracker.repository;

import com.ipotracker.model.LotSizeTier;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface LotSizeRepository extends JpaRepository<LotSizeTier, UUID> {
    List<LotSizeTier> findByIpoId(UUID ipoId);
}
