import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/text_style.dart';
import 'app_surface.dart';

/// A label/value pair for the [InfoTable].
class InfoRow {
  final String label;
  final String value;
  final Color? valueColor;
  const InfoRow(this.label, this.value, {this.valueColor});
}

/// A clean two-column key/value list used by most detail tabs.
class InfoTable extends StatelessWidget {
  final List<InfoRow> rows;
  final EdgeInsetsGeometry padding;
  const InfoTable(this.rows, {super.key, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: padding == EdgeInsets.zero ? const EdgeInsets.all(4) : padding,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: i.isEven ? Colors.transparent : AppColors.scaffold.withValues(alpha: 0.5),
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(12) : Radius.zero,
                  bottom: i == rows.length - 1 ? const Radius.circular(12) : Radius.zero,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(rows[i].label, style: AppTextStyle.label),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.right,
                      style: AppTextStyle.value.copyWith(
                        color: rows[i].valueColor ?? AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Section heading used above cards.
class SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  const SectionTitle(this.title, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
          ],
          Text(title, style: AppTextStyle.h2),
        ],
      ),
    );
  }
}
