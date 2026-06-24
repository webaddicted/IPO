package com.ipotracker.repository;

import com.ipotracker.model.SubscriptionData;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SubscriptionRepository extends JpaRepository<SubscriptionData, UUID> {
    List<SubscriptionData> findByIpoId(UUID ipoId);

    Optional<SubscriptionData> findByIpoIdAndBucket(UUID ipoId, String bucket);
}
