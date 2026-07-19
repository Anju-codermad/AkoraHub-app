import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Revenue chart widget displaying sales trends over time
class RevenueChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> revenueData;
  final String period;

  const RevenueChartWidget({
    super.key,
    required this.revenueData,
    required this.period,
  });

  @override
  State<RevenueChartWidget> createState() => _RevenueChartWidgetState();
}

class _RevenueChartWidgetState extends State<RevenueChartWidget> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Trend',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.period,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'show_chart',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          SizedBox(
            height: 30.h,
            child: Semantics(
              label:
                  'Revenue trend line chart showing sales performance over ${widget.period}',
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < widget.revenueData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                widget.revenueData[value.toInt()]['label'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}k',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      left: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  minX: 0,
                  maxX: (widget.revenueData.length - 1).toDouble(),
                  minY: 0,
                  maxY: 10,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? touchResponse) {
                      setState(() {
                        if (touchResponse == null ||
                            touchResponse.lineBarSpots == null) {
                          _touchedIndex = null;
                          return;
                        }
                        _touchedIndex =
                            touchResponse.lineBarSpots!.first.spotIndex;
                      });
                    },
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor:
                          theme.colorScheme.inverseSurface,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final flSpot = barSpot;
                          return LineTooltipItem(
                            '\${flSpot.y.toStringAsFixed(1)}k',
                            theme.textTheme.bodySmall!.copyWith(
                              color: theme.colorScheme.onInverseSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: widget.revenueData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          (entry.value['value'] as num).toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: index == _touchedIndex ? 6 : 4,
                            color: theme.colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: theme.colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.3),
                            theme.colorScheme.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
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