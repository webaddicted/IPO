"""SQLAlchemy ORM models — rebuilt schema (migration 0003)."""

import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import BigInteger, Boolean, Date, DateTime, Integer, Numeric, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class Ipo(Base):
    __tablename__ = "ipos"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    source_chittorgarh_id: Mapped[int] = mapped_column(BigInteger, unique=True, nullable=False)
    source_slug: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    source_url: Mapped[Optional[str]] = mapped_column(Text)
    company_name: Mapped[str] = mapped_column(String(255), nullable=False)
    logo_url: Mapped[Optional[str]] = mapped_column(Text)
    ipo_type: Mapped[str] = mapped_column(String(20), nullable=False, default="mainline")
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="upcoming")

    offer_price_min: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    offer_price_max: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    issue_price: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    face_value: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    lot_size: Mapped[Optional[int]] = mapped_column(Integer)
    min_investment: Mapped[Optional[Decimal]] = mapped_column(Numeric(14, 2))

    open_date: Mapped[Optional[date]] = mapped_column(Date)
    close_date: Mapped[Optional[date]] = mapped_column(Date)
    allotment_date: Mapped[Optional[date]] = mapped_column(Date)
    refund_date: Mapped[Optional[date]] = mapped_column(Date)
    demat_transfer_date: Mapped[Optional[date]] = mapped_column(Date)
    listing_date: Mapped[Optional[date]] = mapped_column(Date)

    listing_at: Mapped[Optional[str]] = mapped_column(String(50))
    issue_type: Mapped[Optional[str]] = mapped_column(String(100))
    sale_type: Mapped[Optional[str]] = mapped_column(String(100))
    total_issue_size_shares: Mapped[Optional[int]] = mapped_column(BigInteger)
    total_issue_size_amount: Mapped[Optional[Decimal]] = mapped_column(Numeric(16, 2))
    fresh_issue_shares: Mapped[Optional[int]] = mapped_column(BigInteger)
    ofs_shares: Mapped[Optional[int]] = mapped_column(BigInteger)
    market_maker_shares: Mapped[Optional[int]] = mapped_column(BigInteger)
    anchor_shares_offered: Mapped[Optional[int]] = mapped_column(BigInteger)
    anchor_investor_url: Mapped[Optional[str]] = mapped_column(Text)

    promoter_holding_pre: Mapped[Optional[Decimal]] = mapped_column(Numeric(7, 2))
    promoter_holding_post: Mapped[Optional[Decimal]] = mapped_column(Numeric(7, 2))
    registrar_name: Mapped[Optional[str]] = mapped_column(String(255))
    nse_symbol: Mapped[Optional[str]] = mapped_column(String(50))
    bse_scripcode: Mapped[Optional[str]] = mapped_column(String(50))
    prospectus_drhp: Mapped[Optional[str]] = mapped_column(Text)
    prospectus_rhp: Mapped[Optional[str]] = mapped_column(Text)

    latest_gmp: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    latest_gmp_percent: Mapped[Optional[Decimal]] = mapped_column(Numeric(7, 2))
    estimated_listing_price: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    listed_price: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    latest_subscription: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2))

    created_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), server_default=func.now())
    last_scraped_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

    @property
    def registrar(self) -> Optional[str]:
        return self.registrar_name

    @property
    def source_slug_legacy(self) -> str:
        return self.source_slug


class CompanyProfile(Base):
    __tablename__ = "company_profiles"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ipo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), unique=True, nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    industry: Mapped[Optional[str]] = mapped_column(String(255))
    promoters: Mapped[Optional[str]] = mapped_column(Text)
    objectives: Mapped[Optional[str]] = mapped_column(Text)
    website_url: Mapped[Optional[str]] = mapped_column(Text)
    address_line1: Mapped[Optional[str]] = mapped_column(Text)
    address_line2: Mapped[Optional[str]] = mapped_column(Text)
    address_line3: Mapped[Optional[str]] = mapped_column(Text)
    city: Mapped[Optional[str]] = mapped_column(String(100))
    state: Mapped[Optional[str]] = mapped_column(String(100))
    pin_code: Mapped[Optional[str]] = mapped_column(String(20))
    phone: Mapped[Optional[str]] = mapped_column(String(50))
    fax: Mapped[Optional[str]] = mapped_column(String(50))
    email: Mapped[Optional[str]] = mapped_column(String(255))


class IpoContact(Base):
    __tablename__ = "ipo_contacts"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ipo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    contact_type: Mapped[str] = mapped_column(String(30), nullable=False)
    name: Mapped[Optional[str]] = mapped_column(String(255))
    phone: Mapped[Optional[str]] = mapped_column(String(50))
    fax: Mapped[Optional[str]] = mapped_column(String(50))
    email: Mapped[Optional[str]] = mapped_column(String(255))
    website: Mapped[Optional[str]] = mapped_column(Text)
    address: Mapped[Optional[str]] = mapped_column(Text)


class LeadManager(Base):
    __tablename__ = "lead_managers"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ipo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    address: Mapped[Optional[str]] = mapped_column(Text)
    website: Mapped[Optional[str]] = mapped_column(Text)
    email: Mapped[Optional[str]] = mapped_column(String(255))
    phone: Mapped[Optional[str]] = mapped_column(String(100))
    is_primary: Mapped[Optional[bool]] = mapped_column(Boolean, default=False)


class ImportantDate(Base):
    __tablename__ = "important_dates"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ipo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    event: Mapped[str] = mapped_column(String(100), nullable=False)
    event_date: Mapped[Optional[date]] = mapped_column(Date)
    sort_order: Mapped[Optional[int]] = mapped_column(Integer, default=0)


class LotSizeTier(Base):
    __tablename__ = "lot_size_tiers"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ipo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    applicant: Mapped[str] = mapped_column(String(50), nullable=False)
    lots: Mapped[Optional[int]] = mapped_column(Integer)
    shares: Mapped[Optional[int]] = mapped_column(BigInteger)
    amount: Mapped[Optional[Decimal]] = mapped_column(Numeric(14, 2))


class IpoReservation(Base):
    __tablename__ = "ipo_reservations"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ipo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    category: Mapped[str] = mapped_column(String(100), nullable=False)
    shares_offered: Mapped[Optional[int]] = mapped_column(BigInteger)
    percent_of_net_issue: Mapped[Optional[Decimal]] = mapped_column(Numeric(7, 2))
    percent_of_total: Mapped[Optional[Decimal]] = mapped_column(Numeric(7, 2))
    max_allottees: Mapped[Optional[int]] = mapped_column(Integer)

    @property
    def percent_of_total_legacy(self) -> Optional[Decimal]:
        return self.percent_of_total or self.percent_of_net_issue


class AnchorInvestor(Base):
    __tablename__ = "anchor_investors"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ipo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    entity_name: Mapped[Optional[str]] = mapped_column(String(500))
    fund_house: Mapped[Optional[str]] = mapped_column(String(255))
    shares_allotted: Mapped[Optional[int]] = mapped_column(BigInteger)
    amount_cr: Mapped[Optional[Decimal]] = mapped_column(Numeric(14, 4))
    percent_allocated: Mapped[Optional[Decimal]] = mapped_column(Numeric(7, 2))
    percent_of_issue: Mapped[Optional[Decimal]] = mapped_column(Numeric(7, 2))
    sort_order: Mapped[Optional[int]] = mapped_column(Integer, default=0)


class IpoReview(Base):
    __tablename__ = "ipo_reviews"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ipo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), unique=True, nullable=False)
    conclusion: Mapped[Optional[str]] = mapped_column(Text)
    recommendation: Mapped[Optional[str]] = mapped_column(String(50))
    review_conclusion: Mapped[Optional[str]] = mapped_column(String(100))
    cm_rating: Mapped[Optional[Decimal]] = mapped_column(Numeric(6, 2))
    reviewed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))


class DrhpMilestone(Base):
    __tablename__ = "drhp_milestones"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ipo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    milestone_code: Mapped[Optional[int]] = mapped_column(Integer)
    description: Mapped[Optional[str]] = mapped_column(String(255))
    milestone_date: Mapped[Optional[date]] = mapped_column(Date)


class FinancialPeriod(Base):
    __tablename__ = "financial_periods"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ipo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    period: Mapped[Optional[str]] = mapped_column(String(20))
    total_assets: Mapped[Optional[Decimal]] = mapped_column(Numeric(16, 2))
    revenue: Mapped[Optional[Decimal]] = mapped_column(Numeric(16, 2))
    ebitda: Mapped[Optional[Decimal]] = mapped_column(Numeric(16, 2))
    profit_before_tax: Mapped[Optional[Decimal]] = mapped_column(Numeric(16, 2))
    profit_after_tax: Mapped[Optional[Decimal]] = mapped_column(Numeric(16, 2))
    net_worth: Mapped[Optional[Decimal]] = mapped_column(Numeric(16, 2))
    reserves_surplus: Mapped[Optional[Decimal]] = mapped_column(Numeric(16, 2))
    total_borrowing: Mapped[Optional[Decimal]] = mapped_column(Numeric(16, 2))


class KpiMetric(Base):
    __tablename__ = "kpi_metrics"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ipo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    metric: Mapped[str] = mapped_column(String(50), nullable=False)
    value: Mapped[Optional[Decimal]] = mapped_column(Numeric(14, 4))
    unit: Mapped[Optional[str]] = mapped_column(String(20))


class SubscriptionSnapshot(Base):
    __tablename__ = "subscription_snapshots"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ipo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    bucket: Mapped[str] = mapped_column(String(20), nullable=False, default="overall")
    subscription_date: Mapped[Optional[date]] = mapped_column(Date)
    total_subscription: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2))
    qib_subscription: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2))
    nii_subscription: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2))
    bnii_subscription: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2))
    snii_subscription: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2))
    retail_subscription: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2))
    employee_subscription: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2))
    market_maker_subscription: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2))
    total_applications: Mapped[Optional[int]] = mapped_column(BigInteger)
    recorded_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), server_default=func.now())


class GmpHistory(Base):
    __tablename__ = "gmp_history"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ipo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    issue_price: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    gmp_price: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    gmp_percent: Mapped[Optional[Decimal]] = mapped_column(Numeric(7, 2))
    estimated_listing_price: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    recorded_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), server_default=func.now())


class PeerComparison(Base):
    __tablename__ = "peer_comparisons"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ipo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    peer_company_name: Mapped[str] = mapped_column(String(255), nullable=False)
    eps: Mapped[Optional[Decimal]] = mapped_column(Numeric(14, 4))
    nav: Mapped[Optional[Decimal]] = mapped_column(Numeric(14, 4))
    pe_ratio: Mapped[Optional[Decimal]] = mapped_column(Numeric(14, 4))
    ronw: Mapped[Optional[Decimal]] = mapped_column(Numeric(14, 4))
    pbv: Mapped[Optional[Decimal]] = mapped_column(Numeric(14, 4))


# Backward-compat aliases for scrapers being migrated
CompanyInfo = CompanyProfile
FinancialData = FinancialPeriod
KpiData = KpiMetric
GmpData = GmpHistory
SubscriptionData = SubscriptionSnapshot
