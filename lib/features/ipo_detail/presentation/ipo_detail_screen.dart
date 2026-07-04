import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import 'package:untitled_poi/global/base/base_stateless_widget.dart';
import 'package:untitled_poi/global/constant/string_const.dart';
import 'package:untitled_poi/features/ipo_detail/controller/detail_controller.dart';
import 'package:untitled_poi/features/ipo_detail/domain/ipo_detail_model.dart';
import 'package:untitled_poi/features/home/domain/ipo_model.dart';
import 'package:untitled_poi/global/theme/app_colors.dart';
import 'package:untitled_poi/global/theme/text_style.dart';
import 'package:untitled_poi/global/utils/date_utility.dart';
import 'package:untitled_poi/global/utils/global_utility.dart';
import 'package:untitled_poi/global/utils/responsive.dart';
import 'package:untitled_poi/features/widgets/allotment_sheet.dart';
import 'package:untitled_poi/features/widgets/app_surface.dart';
import 'package:untitled_poi/features/widgets/gmp_chart.dart';
import 'package:untitled_poi/features/widgets/info_table.dart';
import 'package:untitled_poi/features/widgets/status_badge.dart';

class IpoDetailScreen extends BaseStatelessWidget {
  const IpoDetailScreen({super.key});

  DetailController get controller => Get.find<DetailController>();

  @override
  Widget initBuild(BuildContext context) {
    final wide = Responsive.isWide(context);

    return Obx(() {
      if (controller.loading.value) {
        return Scaffold(
          backgroundColor: AppColors.scaffold,
          body: _DetailShimmer(wide: wide),
        );
      }
      final d = controller.detail.value;
      if (d == null) {
        return Scaffold(
          backgroundColor: AppColors.scaffold,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Get.back(),
            ),
          ),
          body: EmptyState(
            icon: Icons.error_outline_rounded,
            title: controller.error.value.isEmpty ? StringConst.noData : 'Unable to load',
            subtitle: controller.error.value.isEmpty ? null : controller.error.value,
          ),
        );
      }

      if (wide) {
        return _WideDetailLayout(d: d, controller: controller);
      }
      return _MobileDetailLayout(d: d, controller: controller);
    });
  }
}

class _MobileDetailLayout extends StatelessWidget {
  final IpoDetailModel d;
  final DetailController controller;

  const _MobileDetailLayout({required this.d, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: StringConst.detailTabs.length,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: NestedScrollView(
          headerSliverBuilder: (_, _) => [
            SliverToBoxAdapter(child: _DetailHero(d: d, controller: controller)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBar(),
            ),
          ],
          body: _DetailTabViews(d: d),
        ),
      ),
    );
  }
}

class _WideDetailLayout extends StatelessWidget {
  final IpoDetailModel d;
  final DetailController controller;

  const _WideDetailLayout({required this.d, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: StringConst.detailTabs.length,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 280,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _DetailHero(d: d, controller: controller, compact: true),
                    _SideTabList(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 1,
                    color: AppColors.cardBorder,
                  ),
                  Expanded(
                    child: _DetailTabViews(d: d),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideTabList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    return ListenableBuilder(
      listenable: tabController,
      builder: (context, _) {
        return Container(
          color: AppColors.card,
          child: Column(
            children: [
              for (int i = 0; i < StringConst.detailTabs.length; i++)
                _SideTabItem(
                  label: StringConst.detailTabs[i],
                  selected: tabController.index == i,
                  onTap: () => tabController.animateTo(i),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SideTabItem extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SideTabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SideTabItem> createState() => _SideTabItemState();
}

class _SideTabItemState extends State<_SideTabItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: widget.selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : (_hovered ? AppColors.scaffold : Colors.transparent),
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: widget.selected ? AppColors.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                color: widget.selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StickyTabBar extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: AppColors.card,
      elevation: overlapsContent ? 2 : 0,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context)),
        tabs: [for (final t in StringConst.detailTabs) Tab(text: t)],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _DetailHero extends StatelessWidget {
  final IpoDetailModel d;
  final DetailController controller;
  final bool compact;

  const _DetailHero({
    required this.d,
    required this.controller,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final ipo = d.ipo;
    final gmpColor = (ipo.latestGmp ?? 0) > 0 ? AppColors.gain : AppColors.neutral;
    final isListed = ipo.status == IpoStatus.listed;

    return HeroBanner(
      showBack: true,
      title: ipo.companyName,
      subtitle: DateUtility.range(ipo.openDate, ipo.closeDate),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusBadge(ipo.status),
          const SizedBox(width: 4),
          Obx(() => IconButton(
                onPressed: controller.toggleWatch,
                icon: Icon(
                  controller.watched.value ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                ),
              )),
          IconButton(
            onPressed: () => Get.snackbar(
              'Share',
              'Sharing ${controller.companyNameHint}',
              snackPosition: SnackPosition.BOTTOM,
            ),
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
      bottom: Column(
        children: [
          Row(
            children: [
              MetricChip(
                label: 'Price Band',
                value: GlobalUtility.priceBand(ipo.offerPriceMin, ipo.offerPriceMax),
                icon: Icons.currency_rupee_rounded,
              ),
              const SizedBox(width: 8),
              MetricChip(
                label: 'Lot Size',
                value: '${ipo.lotSize ?? '—'}',
                icon: Icons.layers_rounded,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              MetricChip(
                label: isListed ? 'Listing Price' : 'Expected GMP',
                value: isListed
                    ? GlobalUtility.rupee(ipo.listedPrice)
                    : '${GlobalUtility.rupee(ipo.latestGmp)} (${GlobalUtility.percent(ipo.latestGmpPercent)})',
                valueColor: isListed ? Colors.white : (gmpColor == AppColors.neutral ? Colors.white : gmpColor),
                icon: isListed ? Icons.show_chart_rounded : Icons.trending_up_rounded,
              ),
              const SizedBox(width: 8),
              MetricChip(
                label: 'Subscription',
                value: GlobalUtility.times(ipo.latestSubscription),
                icon: Icons.people_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text(StringConst.checkAllotment),
              onPressed: () => AllotmentSheet.show(
                context,
                ipoId: ipo.id,
                companyName: ipo.companyName,
                registrar: d.registrar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTabViews extends StatelessWidget {
  final IpoDetailModel d;
  const _DetailTabViews({required this.d});

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPadding(context);
    return TabBarView(
      children: [
        _DetailTabContent(d: d, tab: _DetailTab.ipoDetails, padding: hPad),
        _DetailTabContent(d: d, tab: _DetailTab.subscription, padding: hPad),
        _DetailTabContent(d: d, tab: _DetailTab.dayWiseSub, padding: hPad),
        _DetailTabContent(d: d, tab: _DetailTab.gmp, padding: hPad),
        _DetailTabContent(d: d, tab: _DetailTab.importantDates, padding: hPad),
        _DetailTabContent(d: d, tab: _DetailTab.lotSize, padding: hPad),
        _DetailTabContent(d: d, tab: _DetailTab.financials, padding: hPad),
        _DetailTabContent(d: d, tab: _DetailTab.kpi, padding: hPad),
        _DetailTabContent(d: d, tab: _DetailTab.reservation, padding: hPad),
        _DetailTabContent(d: d, tab: _DetailTab.aboutCompany, padding: hPad),
        _DetailTabContent(d: d, tab: _DetailTab.objectives, padding: hPad),
        _DetailTabContent(d: d, tab: _DetailTab.disclaimer, padding: hPad),
      ],
    );
  }
}

enum _DetailTab {
  ipoDetails,
  subscription,
  dayWiseSub,
  gmp,
  importantDates,
  lotSize,
  financials,
  kpi,
  reservation,
  aboutCompany,
  objectives,
  disclaimer,
}

class _DetailTabContent extends StatelessWidget {
  final IpoDetailModel d;
  final _DetailTab tab;
  final double padding;

  const _DetailTabContent({
    required this.d,
    required this.tab,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
      child: Responsive.constrain(_buildTab()),
    );
  }

  Widget _buildTab() => switch (tab) {
        _DetailTab.ipoDetails => _ipoDetailsTab(),
        _DetailTab.subscription => _subscriptionTab(),
        _DetailTab.dayWiseSub => _dayWiseSubTab(),
        _DetailTab.gmp => _gmpTab(),
        _DetailTab.importantDates => _importantDatesTab(),
        _DetailTab.lotSize => _lotSizeTab(),
        _DetailTab.financials => _financialsTab(),
        _DetailTab.kpi => _kpiTab(),
        _DetailTab.reservation => _reservationTab(),
        _DetailTab.aboutCompany => _aboutCompanyTab(),
        _DetailTab.objectives => _objectivesTab(),
        _DetailTab.disclaimer => _disclaimerTab(),
      };

  Widget _ipoDetailsTab() {
    final ipo = d.ipo;
    return InfoTable([
      InfoRow('IPO Date', DateUtility.range(ipo.openDate, ipo.closeDate)),
      InfoRow('Listed On', DateUtility.formatWithDay(ipo.listingDate)),
      InfoRow('Face Value',
          d.faceValue == null ? '—' : '${GlobalUtility.rupee(d.faceValue)} per share'),
      InfoRow('Price Band', GlobalUtility.priceBand(ipo.offerPriceMin, ipo.offerPriceMax)),
      InfoRow('Issue Price',
          d.issuePrice == null ? '—' : '${GlobalUtility.rupee(d.issuePrice)} per share'),
      InfoRow('Lot Size', '${ipo.lotSize ?? '—'} Shares'),
      if (d.minInvestment != null)
        InfoRow('Min Investment', GlobalUtility.rupee(d.minInvestment)),
      InfoRow('Sale Type', d.saleType ?? '—'),
      InfoRow('Issue Type', d.issueType ?? '—'),
      InfoRow('Listing At', ipo.listingAt ?? '—'),
      InfoRow('Total Issue Size',
          '${GlobalUtility.group(d.totalIssueSizeShares)} shares (~${GlobalUtility.compactRupee(d.totalIssueSizeAmount)})'),
      if (d.marketMakerShares != null)
        InfoRow('Market Maker Portion', '${GlobalUtility.group(d.marketMakerShares)} shares'),
      InfoRow('Subscription', GlobalUtility.times(ipo.latestSubscription)),
      InfoRow('Expected GMP',
          '${GlobalUtility.rupee(ipo.latestGmp)} (${GlobalUtility.percent(ipo.latestGmpPercent)})'),
      if (d.registrar != null) InfoRow('Registrar', d.registrar!),
    ]);
  }

  Widget _subscriptionTab() {
    final s = d.overallSubscription;
    if (s == null) return _empty();
    return InfoTable([
      InfoRow('QIB', GlobalUtility.times(s.qib)),
      InfoRow('NII', GlobalUtility.times(s.nii)),
      InfoRow('Retail', GlobalUtility.times(s.retail)),
      if (s.employee != null) InfoRow('Employee', GlobalUtility.times(s.employee)),
      InfoRow('Total', GlobalUtility.times(s.total), valueColor: AppColors.accent),
    ]);
  }

  Widget _dayWiseSubTab() {
    final days = d.dayWise;
    if (days.isEmpty) return _empty();
    return Column(
      children: [
        for (final day in days) ...[
          SectionTitle(day.bucket.toUpperCase(), icon: Icons.timeline_rounded),
          InfoTable([
            InfoRow('QIB', GlobalUtility.times(day.qib)),
            InfoRow('NII', GlobalUtility.times(day.nii)),
            InfoRow('Retail', GlobalUtility.times(day.retail)),
            InfoRow('Total', GlobalUtility.times(day.total), valueColor: AppColors.accent),
          ]),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _gmpTab() {
    return Column(
      children: [
        GmpChart(d.gmp),
        const SizedBox(height: 12),
        if (d.gmp.isNotEmpty)
          InfoTable([
            for (final g in d.gmp.reversed)
              InfoRow(
                DateUtility.format(g.recordedAt),
                '${GlobalUtility.rupee(g.price)} (${GlobalUtility.percent(g.percent)})',
                valueColor: (g.price ?? 0) > 0 ? AppColors.gain : AppColors.neutral,
              ),
          ]),
      ],
    );
  }

  Widget _importantDatesTab() {
    if (d.importantDates.isEmpty) return _empty();
    return InfoTable([
      for (final e in d.importantDates)
        InfoRow(e.event, DateUtility.format(e.date)),
    ]);
  }

  Widget _lotSizeTab() {
    if (d.lotSizes.isEmpty) return _empty();
    return InfoTable([
      for (final l in d.lotSizes)
        InfoRow('${l.applicant} (${l.lots ?? '—'} lot)',
            '${GlobalUtility.group(l.shares)} sh • ${GlobalUtility.rupee(l.amount)}'),
    ]);
  }

  Widget _financialsTab() {
    if (d.financials.isEmpty) return _empty();
    return Column(
      children: [
        for (final f in d.financials) ...[
          SectionTitle(f.period ?? '—', icon: Icons.bar_chart_rounded),
          InfoTable([
            InfoRow('Revenue', GlobalUtility.compactRupee(_lakh(f.revenue))),
            InfoRow('Profit After Tax', GlobalUtility.compactRupee(_lakh(f.pat))),
            InfoRow('Total Assets', GlobalUtility.compactRupee(_lakh(f.totalAssets))),
            InfoRow('Net Worth', GlobalUtility.compactRupee(_lakh(f.netWorth))),
          ]),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  num? _lakh(num? v) => v == null ? null : v * 100000;

  Widget _kpiTab() {
    if (d.kpis.isEmpty) return _empty();
    String fmt(KpiRow k) {
      final v = k.value;
      if (v == null) return '—';
      return switch (k.unit) {
        '%' => '${v.toStringAsFixed(2)}%',
        'x' => '${v.toStringAsFixed(2)}x',
        _ => v.toStringAsFixed(2),
      };
    }
    return InfoTable([for (final k in d.kpis) InfoRow(_kpiLabel(k.metric), fmt(k))]);
  }

  String _kpiLabel(String metric) => switch (metric) {
        'ROE' => 'Return on Equity (ROE)',
        'ROCE' => 'Return on Capital (ROCE)',
        'EPS' => 'Earnings Per Share (EPS)',
        'PE_PRE' => 'P/E (Pre-IPO)',
        'PE_POST' => 'P/E (Post-IPO)',
        'RONW' => 'Return on Net Worth',
        'DEBT_EQUITY' => 'Debt / Equity',
        _ => metric,
      };

  Widget _reservationTab() {
    if (d.reservations.isEmpty) return _empty();
    return InfoTable([
      for (final r in d.reservations)
        InfoRow(r.category,
            '${GlobalUtility.group(r.shares)} sh (${GlobalUtility.percent(r.percent)})'),
    ]);
  }

  Widget _aboutCompanyTab() {
    final c = d.company;
    if (c == null) return _empty();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.description != null) ...[
          const SectionTitle('About', icon: Icons.business_rounded),
          AppSurfaceCard(
            child: Text(c.description!, style: AppTextStyle.body),
          ),
          const SizedBox(height: 12),
        ],
        InfoTable([
          if (c.promoters != null) InfoRow('Promoters', c.promoters!),
          if (c.leadManagers != null) InfoRow('Lead Manager', c.leadManagers!),
          if (d.registrar != null) InfoRow('Registrar', d.registrar!),
          if (c.websiteUrl != null) InfoRow('Website', c.websiteUrl!),
        ]),
      ],
    );
  }

  Widget _objectivesTab() {
    final obj = d.company?.objectives;
    if (obj == null || obj.isEmpty) return _empty();
    return AppSurfaceCard(
      child: Text(obj, style: AppTextStyle.body),
    );
  }

  Widget _disclaimerTab() {
    return AppSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.statusUpcoming.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.info_outline_rounded, color: AppColors.statusUpcoming, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(StringConst.disclaimer, style: AppTextStyle.label.copyWith(height: 1.6))),
        ],
      ),
    );
  }

  Widget _empty() => const EmptyState(
        icon: Icons.inbox_rounded,
        title: StringConst.noData,
      );
}

/// Skeleton placeholder while the detail aggregate loads.
class _DetailShimmer extends StatelessWidget {
  final bool wide;
  const _DetailShimmer({required this.wide});

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPadding(context);
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.card,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(hPad, MediaQuery.paddingOf(context).top + 8, hPad, 24),
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(width: 40, height: 40, radius: 12),
                  const SizedBox(height: 16),
                  _box(width: wide ? 320 : double.infinity, height: 28, radius: 8),
                  const SizedBox(height: 10),
                  _box(width: wide ? 200 : 180, height: 16, radius: 6),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _box(height: 56, radius: 12)),
                      const SizedBox(width: 8),
                      Expanded(child: _box(height: 56, radius: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _box(height: 56, radius: 12)),
                      const SizedBox(width: 8),
                      Expanded(child: _box(height: 56, radius: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _box(width: double.infinity, height: 48, radius: 12),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.card,
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
              child: Row(
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    _box(width: 72, height: 24, radius: 6),
                  ],
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _box(width: double.infinity, height: i.isEven ? 52 : 44, radius: 12),
                ),
                childCount: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box({double? width, required double height, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
