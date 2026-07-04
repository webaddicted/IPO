import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:untitled_poi/features/ipo_detail/domain/ipo_detail_model.dart';
import 'package:untitled_poi/global/theme/app_colors.dart';
import 'package:untitled_poi/global/theme/text_style.dart';
import 'package:untitled_poi/features/widgets/app_surface.dart';

/// Day-wise GMP line chart with gradient fill.
class GmpChart extends StatelessWidget {
  final List<GmpPoint> points;
  const GmpChart(this.points, {super.key});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const AppSurfaceCard(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No GMP history', style: AppTextStyle.label)),
        ),
      );
    }

    final spots = <FlSpot>[
      for (int i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), (points[i].price ?? 0).toDouble()),
    ];
    final maxY = spots.map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b);

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.show_chart_rounded, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text('GMP Trend', style: AppTextStyle.h2),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY <= 0 ? 10 : maxY * 1.3,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text(
                          '₹${v.toInt()}',
                          style: AppTextStyle.caption,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= points.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('Day ${i + 1}', style: AppTextStyle.caption),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppColors.primary,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.25),
                            AppColors.primary.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
