package com.ipotracker.repository;

import com.ipotracker.model.GmpData;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface GmpRepository extends JpaRepository<GmpData, UUID> {
    List<GmpData> findByIpoIdOrderByRecordedAtAsc(UUID ipoId);

    Optional<GmpData> findFirstByIpoIdOrderByRecordedAtDesc(UUID ipoId);
}
