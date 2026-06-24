package com.ipotracker.repository;

import com.ipotracker.model.Ipo;
import com.ipotracker.model.IpoKind;
import com.ipotracker.model.IpoStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface IpoRepository extends JpaRepository<Ipo, UUID> {
    Optional<Ipo> findBySourceSlug(String sourceSlug);

    List<Ipo> findByIpoTypeAndStatusInOrderByOpenDateDesc(IpoKind ipoType, List<IpoStatus> statuses);

    List<Ipo> findByIpoTypeAndStatusOrderByListingDateDesc(IpoKind ipoType, IpoStatus status);
}
