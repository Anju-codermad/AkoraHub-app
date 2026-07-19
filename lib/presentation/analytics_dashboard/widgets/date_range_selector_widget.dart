import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Date range selector widget for analytics dashboard
/// Allows users to select predefined or custom date ranges
class DateRangeSelectorWidget extends StatefulWidget {
  final Function(DateTime startDate, DateTime endDate) onDateRangeChanged;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const DateRangeSelectorWidget({
    super.key,
    required this.onDateRangeChanged,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<DateRangeSelectorWidget> createState() =>
      _DateRangeSelectorWidgetState();
}

class _DateRangeSelectorWidgetState extends State<DateRangeSelectorWidget> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedRange = 'Last 7 Days';

  final List<Map<String, dynamic>> _predefinedRanges = [
    {'label': 'Today', 'days': 0},
    {'label': 'Last 7 Days', 'days': 7},
    {'label': 'Last 30 Days', 'days': 30},
    {'label': 'Last 90 Days', 'days': 90},
    {'label': 'This Year', 'days': -1},
    {'label': 'Custom', 'days': -2},
  ];

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate ??
        DateTime.now().subtract(const Duration(days: 7));
    _endDate = widget.initialEndDate ?? DateTime.now();
  }

  void _selectPredefinedRange(String label, int days) {
    setState(() {
      _selectedRange = label;
      _endDate = DateTime.now();

      if (days == 0) {
        _startDate = DateTime.now();
      } else if (days == -1) {
        _startDate = DateTime(DateTime.now().year, 1, 1);
      } else if (days == -2) {
        _showCustomDatePicker();
        return;
      } else {
        _startDate = DateTime.now().subtract(Duration(days: days));
      }

      widget.onDateRangeChanged(_startDate, _endDate);
    });
  }

  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedRange = 'Custom';
      });
      widget.onDateRangeChanged(_startDate, _endDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
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
            children: [
              CustomIconWidget(
                iconName: 'calendar_today',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Date Range',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _predefinedRanges.map((range) {
              final isSelected = _selectedRange == range['label'];
              return InkWell(
                onTap: () =>
                    _selectPredefinedRange(range['label'], range['days']),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    range['label'],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(_startDate),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                CustomIconWidget(
                  iconName: 'arrow_forward',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'To',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(_endDate),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
