import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../model/bean/ipo_model.dart';
import '../theme/app_colors.dart';
import '../theme/text_style.dart';
import '../utils/date_utility.dart';
import '../utils/global_utility.dart';
import 'app_surface.dart';
import 'status_badge.dart';

/// Listing card with accent stripe, hover lift, and subscription bar.
class IpoCard extends StatelessWidget {
  final IpoModel ipo;
  final VoidCallback onTap;
  const IpoCard({super.key, required this.ipo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gmpColor = _gmpColor();
    return AppSurfaceCard(
      showAccent: true,
      accentColor: _statusAccent(),
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _logo(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ipo.companyName,
                      style: AppTextStyle.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            DateUtility.range(ipo.openDate, ipo.closeDate),
                            style: AppTextStyle.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(ipo.status),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.cardShimmer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                _metric('Price Range',
                    GlobalUtility.priceBand(ipo.offerPriceMin, ipo.offerPriceMax)),
                _divider(),
                _metric('Lot Size', '${ipo.lotSize ?? '—'}'),
                _divider(),
                _gmpMetric(gmpColor),
              ],
            ),
          ),
          if (ipo.latestSubscription != null) ...[
            const SizedBox(height: 14),
            _subscriptionBar(),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('View details', style: AppTextStyle.caption.copyWith(color: AppColors.primary)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusAccent() => switch (ipo.status) {
        IpoStatus.open => AppColors.statusOpen,
        IpoStatus.upcoming => AppColors.statusUpcoming,
        IpoStatus.closed => AppColors.statusClosed,
        IpoStatus.listed => AppColors.statusListed,
      };

  Color? _gmpColor() {
    final gmp = ipo.latestGmp;
    if (gmp == null || gmp == 0) return AppColors.neutral;
    return gmp > 0 ? AppColors.gain : AppColors.loss;
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: AppColors.divider,
      );

  Widget _logo() {
    final initials = ipo.companyName.isNotEmpty
        ? ipo.companyName.trim()[0].toUpperCase()
        : '?';
    final placeholder = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.accent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    );
    if (ipo.logoUrl == null || ipo.logoUrl!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CachedNetworkImage(
        imageUrl: ipo.logoUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }

  Widget _metric(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AppTextStyle.metricLabel),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyle.value.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

  Widget _gmpMetric(Color? color) {
    final gmp = ipo.latestGmp;
    final pct = ipo.latestGmpPercent;
    final text = gmp == null
        ? '—'
        : '₹${gmp.toStringAsFixed(0)}'
            '${pct != null ? ' (${pct.toStringAsFixed(1)}%)' : ''}';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GMP', style: AppTextStyle.metricLabel),
          const SizedBox(height: 4),
          Text(
            text,
            style: AppTextStyle.value.copyWith(color: color, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _subscriptionBar() {
    final sub = ipo.latestSubscription!.toDouble();
    final fraction = (sub / 10).clamp(0.02, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subscription', style: AppTextStyle.caption),
            Text(
              GlobalUtility.times(sub),
              style: AppTextStyle.caption.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
      ],
    );
  }
}
