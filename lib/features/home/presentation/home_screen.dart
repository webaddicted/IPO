import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import 'package:untitled_poi/global/base/base_stateless_widget.dart';
import 'package:untitled_poi/global/constant/routers_const.dart';
import 'package:untitled_poi/global/constant/string_const.dart';
import 'package:untitled_poi/features/home/controller/home_controller.dart';
import 'package:untitled_poi/global/theme/app_colors.dart';
import 'package:untitled_poi/global/theme/text_style.dart';
import 'package:untitled_poi/global/utils/responsive.dart';
import 'package:untitled_poi/features/widgets/app_surface.dart';
import 'package:untitled_poi/features/widgets/ipo_card.dart';

class HomeScreen extends BaseStatelessWidget {
  const HomeScreen({super.key});

  HomeController get controller => Get.find<HomeController>();

  static const _navIcons = [
    Icons.account_balance_rounded,
    Icons.storefront_rounded,
    Icons.local_offer_rounded,
  ];

  static const _navLabels = [
    StringConst.mainlineIpo,
    StringConst.smeIpo,
    StringConst.offers,
  ];

  @override
  Widget initBuild(BuildContext context) {
    final wide = Responsive.isWide(context);

    if (wide) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Obx(() => Row(
              children: [
                _SideNav(
                  selectedIndex: controller.navIndex.value,
                  onSelected: controller.selectNav,
                ),
                Expanded(child: _MainContent(controller: controller)),
              ],
            )),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: _MainContent(controller: controller),
      bottomNavigationBar: Obx(() => NavigationBar(
            selectedIndex: controller.navIndex.value,
            onDestinationSelected: controller.selectNav,
            destinations: [
              for (int i = 0; i < _navLabels.length; i++)
                NavigationDestination(
                  icon: Icon(_navIcons[i]),
                  selectedIcon: Icon(_navIcons[i]),
                  label: _navLabels[i],
                ),
            ],
          )),
    );
  }
}

class _SideNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _SideNav({required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 14),
                Text(StringConst.appName, style: AppTextStyle.display.copyWith(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  'Track IPOs, GMP & more',
                  style: AppTextStyle.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < HomeScreen._navLabels.length; i++)
            _NavItem(
              icon: HomeScreen._navIcons[i],
              label: HomeScreen._navLabels[i],
              selected: selectedIndex == i,
              onTap: () => onSelected(i),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Data for informational use only',
              style: AppTextStyle.caption.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: widget.selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (_hovered ? AppColors.scaffold : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.selected ? AppColors.primary : AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                      color: widget.selected ? AppColors.primary : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  final HomeController controller;
  const _MainContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final nav = controller.navIndex.value;
      final kindLabel = nav == 1 ? 'SME' : 'Mainline';
      return RefreshIndicator(
        onRefresh: controller.refreshData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: HeroBanner(
                title: nav == 2 ? 'Exclusive Offers' : '$kindLabel IPOs',
                subtitle: nav == 2
                    ? 'Broker deals & launch perks'
                    : 'Real-time GMP, subscription & listing data',
                bottom: nav != 2
                    ? SegmentedPills(
                        labels: const [StringConst.currentIpo, StringConst.listedIpo],
                        selectedIndex: controller.tabIndex.value,
                        onChanged: controller.selectTab,
                      )
                    : null,
              ),
            ),
            if (nav == 2)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _OffersPlaceholder(),
              )
            else
              _IpoListSliver(controller: controller),
          ],
        ),
      );
    });
  }
}

class _IpoListSliver extends StatelessWidget {
  final HomeController controller;
  const _IpoListSliver({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Rebuild when nav/tab, loading state, or list data changes.
      controller.navIndex.value;
      controller.tabIndex.value;
      if (controller.loading.value) {
        return SliverPadding(
          padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
          sliver: SliverToBoxAdapter(child: _LoadingGrid(context: context)),
        );
      }
      if (controller.error.isNotEmpty && controller.ipos.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorView(message: controller.error.value, onRetry: controller.refreshData),
        );
      }
      if (controller.ipos.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.inbox_rounded,
            title: StringConst.noData,
            subtitle: 'Pull to refresh or check back later',
          ),
        );
      }

      final cols = Responsive.gridColumns(context);
      final hPad = Responsive.horizontalPadding(context);

      if (cols == 1) {
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
          sliver: SliverList.separated(
            itemCount: controller.ipos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final ipo = controller.ipos[i];
              return IpoCard(
                ipo: ipo,
                onTap: () => Get.toNamed(
                  Routes.detail,
                  arguments: {'id': ipo.id, 'name': ipo.companyName},
                ),
              );
            },
          ),
        );
      }

      return SliverPadding(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: Responsive.isDesktop(context) ? 1.35 : 1.15,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final ipo = controller.ipos[i];
              return IpoCard(
                ipo: ipo,
                onTap: () => Get.toNamed(
                  Routes.detail,
                  arguments: {'id': ipo.id, 'name': ipo.companyName},
                ),
              );
            },
            childCount: controller.ipos.length,
          ),
        ),
      );
    });
  }
}

class _LoadingGrid extends StatelessWidget {
  final BuildContext context;
  const _LoadingGrid({required this.context});

  @override
  Widget build(BuildContext _) {
    final cols = Responsive.gridColumns(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: cols == 1 ? 1.6 : 1.2,
      ),
      itemCount: cols == 1 ? 4 : 6,
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: AppColors.card,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Connection issue',
      subtitle: message,
    ).copyWithAction(
      FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Try again'),
      ),
    );
  }
}

class _OffersPlaceholder extends StatelessWidget {
  const _OffersPlaceholder();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.local_offer_rounded,
      title: 'Offers coming soon',
      subtitle: 'Exclusive broker deals and IPO launch perks will appear here',
    );
  }
}

extension on Widget {
  Widget copyWithAction(Widget action) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [this, const SizedBox(height: 20), action],
    );
  }
}
