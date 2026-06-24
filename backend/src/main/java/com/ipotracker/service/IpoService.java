package com.ipotracker.service;

import com.ipotracker.dto.Dtos;
import com.ipotracker.model.IpoKind;
import com.ipotracker.model.IpoStatus;
import com.ipotracker.model.Ipo;
import com.ipotracker.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Read-side service: assembles DTOs the REST controllers serve. */
@Service
@Transactional(readOnly = true)
public class IpoService {

    private final IpoRepository ipoRepo;
    private final GmpRepository gmpRepo;
    private final SubscriptionRepository subRepo;
    private final FinancialRepository finRepo;
    private final KpiRepository kpiRepo;
    private final ReservationRepository resvRepo;
    private final LotSizeRepository lotRepo;
    private final ImportantDateRepository dateRepo;
    private final CompanyInfoRepository companyRepo;

    public IpoService(IpoRepository ipoRepo, GmpRepository gmpRepo, SubscriptionRepository subRepo,
                      FinancialRepository finRepo, KpiRepository kpiRepo, ReservationRepository resvRepo,
                      LotSizeRepository lotRepo, ImportantDateRepository dateRepo,
                      CompanyInfoRepository companyRepo) {
        this.ipoRepo = ipoRepo;
        this.gmpRepo = gmpRepo;
        this.subRepo = subRepo;
        this.finRepo = finRepo;
        this.kpiRepo = kpiRepo;
        this.resvRepo = resvRepo;
        this.lotRepo = lotRepo;
        this.dateRepo = dateRepo;
        this.companyRepo = companyRepo;
    }

    /** Current = upcoming + open + closed (i.e. not yet listed). */
    public List<Dtos.IpoSummary> current(IpoKind type) {
        return ipoRepo.findByIpoTypeAndStatusInOrderByOpenDateDesc(
                        type, List.of(IpoStatus.upcoming, IpoStatus.open, IpoStatus.closed))
                .stream().map(Dtos.IpoSummary::from).toList();
    }

    public List<Dtos.IpoSummary> listed(IpoKind type) {
        return ipoRepo.findByIpoTypeAndStatusOrderByListingDateDesc(type, IpoStatus.listed)
                .stream().map(Dtos.IpoSummary::from).toList();
    }

    public Dtos.IpoDetail detail(UUID id) {
        Ipo ipo = ipoRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("IPO not found: " + id));
        return new Dtos.IpoDetail(
                ipo,
                gmpRepo.findByIpoIdOrderByRecordedAtAsc(id),
                subRepo.findByIpoId(id),
                finRepo.findByIpoIdOrderByPeriodDesc(id),
                kpiRepo.findByIpoId(id),
                resvRepo.findByIpoId(id),
                lotRepo.findByIpoId(id),
                dateRepo.findByIpoIdOrderBySortOrderAsc(id),
                companyRepo.findByIpoId(id).orElse(null));
    }

    public List<com.ipotracker.model.GmpData> gmpHistory(UUID id) {
        return gmpRepo.findByIpoIdOrderByRecordedAtAsc(id);
    }

    public List<com.ipotracker.model.SubscriptionData> subscriptions(UUID id) {
        return subRepo.findByIpoId(id);
    }
}
