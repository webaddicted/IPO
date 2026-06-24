package com.ipotracker.repository;

import com.ipotracker.model.IpoReservation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ReservationRepository extends JpaRepository<IpoReservation, UUID> {
    List<IpoReservation> findByIpoId(UUID ipoId);
}
