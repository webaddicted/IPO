"""IPO API response schemas."""

from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from app.schemas.base import CamelModel


class IpoSummary(CamelModel):
    id: UUID
    source_slug: str
    company_name: str
    logo_url: str | None = None
    ipo_type: str
    status: str
    offer_price_min: Decimal | None = None
    offer_price_max: Decimal | None = None
    issue_price: Decimal | None = None
    listed_price: Decimal | None = None
    lot_size: int | None = None
    open_date: date | None = None
    close_date: date | None = None
    listing_date: date | None = None
    listing_at: str | None = None
    latest_gmp: Decimal | None = None
    latest_gmp_percent: Decimal | None = None
    estimated_listing_price: Decimal | None = None
    latest_subscription: Decimal | None = None


class GmpPoint(CamelModel):
    id: UUID | None = None
    ipo_id: UUID | None = None
    issue_price: Decimal | None = None
    gmp_price: Decimal | None = None
    gmp_percent: Decimal | None = None
    estimated_listing_price: Decimal | None = None
    recorded_at: datetime | None = None


class SubscriptionRow(CamelModel):
    id: UUID | None = None
    ipo_id: UUID | None = None
    bucket: str = "overall"
    total_subscription: Decimal | None = None
    qib_subscription: Decimal | None = None
    nii_subscription: Decimal | None = None
    bnii_subscription: Decimal | None = None
    snii_subscription: Decimal | None = None
    retail_subscription: Decimal | None = None
    employee_subscription: Decimal | None = None
    market_maker_subscription: Decimal | None = None
    total_applications: int | None = None
    subscription_date: date | None = None
    recorded_at: datetime | None = None


class FinancialRow(CamelModel):
    id: UUID | None = None
    ipo_id: UUID | None = None
    period: str | None = None
    revenue: Decimal | None = None
    ebitda: Decimal | None = None
    profit_before_tax: Decimal | None = None
    profit_after_tax: Decimal | None = None
    total_assets: Decimal | None = None
    net_worth: Decimal | None = None
    reserves_surplus: Decimal | None = None
    total_borrowing: Decimal | None = None


class KpiRow(CamelModel):
    id: UUID | None = None
    ipo_id: UUID | None = None
    metric: str
    value: Decimal | None = None
    unit: str | None = None


class ReservationRow(CamelModel):
    id: UUID | None = None
    ipo_id: UUID | None = None
    category: str
    shares_offered: int | None = None
    percent_of_net_issue: Decimal | None = None
    percent_of_total: Decimal | None = None
    max_allottees: int | None = None


class LotSizeRow(CamelModel):
    id: UUID | None = None
    ipo_id: UUID | None = None
    applicant: str
    lots: int | None = None
    shares: int | None = None
    amount: Decimal | None = None


class ImportantDateRow(CamelModel):
    id: UUID | None = None
    ipo_id: UUID | None = None
    event: str
    event_date: date | None = None
    sort_order: int | None = None


class CompanyProfileSchema(CamelModel):
    id: UUID | None = None
    ipo_id: UUID | None = None
    description: str | None = None
    industry: str | None = None
    promoters: str | None = None
    objectives: str | None = None
    website_url: str | None = None
    address_line1: str | None = None
    city: str | None = None
    state: str | None = None
    phone: str | None = None
    email: str | None = None


class ContactRow(CamelModel):
    id: UUID | None = None
    ipo_id: UUID | None = None
    contact_type: str
    name: str | None = None
    phone: str | None = None
    fax: str | None = None
    email: str | None = None
    website: str | None = None
    address: str | None = None


class LeadManagerRow(CamelModel):
    id: UUID | None = None
    ipo_id: UUID | None = None
    name: str
    address: str | None = None
    website: str | None = None
    email: str | None = None
    phone: str | None = None
    is_primary: bool | None = None


class AnchorInvestorRow(CamelModel):
    id: UUID | None = None
    ipo_id: UUID | None = None
    entity_name: str | None = None
    fund_house: str | None = None
    shares_allotted: int | None = None
    amount_cr: Decimal | None = None
    percent_allocated: Decimal | None = None
    percent_of_issue: Decimal | None = None
    sort_order: int | None = None


class ReviewRow(CamelModel):
    id: UUID | None = None
    ipo_id: UUID | None = None
    conclusion: str | None = None
    recommendation: str | None = None
    review_conclusion: str | None = None
    cm_rating: Decimal | None = None
    reviewed_at: datetime | None = None


class DrhpMilestoneRow(CamelModel):
    id: UUID | None = None
    ipo_id: UUID | None = None
    milestone_code: int | None = None
    description: str | None = None
    milestone_date: date | None = None


class PeerRow(CamelModel):
    id: UUID | None = None
    ipo_id: UUID | None = None
    peer_company_name: str
    eps: Decimal | None = None
    nav: Decimal | None = None
    pe_ratio: Decimal | None = None


# Backward-compat alias
CompanyInfoSchema = CompanyProfileSchema


class IpoEntity(CamelModel):
    """Full IPO entity nested under detail aggregate."""

    id: UUID
    source_slug: str
    source_chittorgarh_id: int | None = None
    company_name: str
    logo_url: str | None = None
    ipo_type: str
    status: str
    offer_price_min: Decimal | None = None
    offer_price_max: Decimal | None = None
    issue_price: Decimal | None = None
    face_value: Decimal | None = None
    lot_size: int | None = None
    min_investment: Decimal | None = None
    open_date: date | None = None
    close_date: date | None = None
    allotment_date: date | None = None
    refund_date: date | None = None
    demat_transfer_date: date | None = None
    listing_date: date | None = None
    listing_at: str | None = None
    issue_type: str | None = None
    sale_type: str | None = None
    total_issue_size_shares: int | None = None
    total_issue_size_amount: Decimal | None = None
    fresh_issue_shares: int | None = None
    ofs_shares: int | None = None
    market_maker_shares: int | None = None
    anchor_shares_offered: int | None = None
    promoter_holding_pre: Decimal | None = None
    promoter_holding_post: Decimal | None = None
    listed_price: Decimal | None = None
    estimated_listing_price: Decimal | None = None
    latest_gmp: Decimal | None = None
    latest_gmp_percent: Decimal | None = None
    latest_subscription: Decimal | None = None
    registrar: str | None = None
    nse_symbol: str | None = None
    bse_scripcode: str | None = None
    prospectus_drhp: str | None = None
    prospectus_rhp: str | None = None
    source_url: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class IpoDetail(CamelModel):
    ipo: IpoEntity
    gmp: list[GmpPoint] = []
    subscriptions: list[SubscriptionRow] = []
    financials: list[FinancialRow] = []
    kpis: list[KpiRow] = []
    reservations: list[ReservationRow] = []
    lot_sizes: list[LotSizeRow] = []
    important_dates: list[ImportantDateRow] = []
    company: CompanyProfileSchema | None = None
    contacts: list[ContactRow] = []
    lead_managers: list[LeadManagerRow] = []
    anchor_investors: list[AnchorInvestorRow] = []
    review: ReviewRow | None = None
    drhp_milestones: list[DrhpMilestoneRow] = []
    peers: list[PeerRow] = []
