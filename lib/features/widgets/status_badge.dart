import 'package:flutter/material.dart';

import 'package:untitled_poi/features/home/domain/ipo_model.dart';
import 'package:untitled_poi/global/theme/app_colors.dart';

/// Coloured pill showing IPO status with dot indicator.
class StatusBadge extends StatelessWidget {
  final IpoStatus status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      IpoStatus.open => (AppColors.statusOpen, 'Open'),
      IpoStatus.upcoming => (AppColors.statusUpcoming, 'Upcoming'),
      IpoStatus.closed => (AppColors.statusClosed, 'Closed'),
      IpoStatus.listed => (AppColors.statusListed, 'Listed'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
