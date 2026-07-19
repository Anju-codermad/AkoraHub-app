import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Pricing Section Widget
/// Handles product pricing with multi-currency support
class PricingSectionWidget extends StatefulWidget {
  final TextEditingController priceController;
  final String selectedCurrency;
  final Function(String) onCurrencyChanged;
  final VoidCallback onChanged;

  const PricingSectionWidget({
    super.key,
    required this.priceController,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.onChanged,
  });

  @override
  State<PricingSectionWidget> createState() => _PricingSectionWidgetState();
}

class _PricingSectionWidgetState extends State<PricingSectionWidget> {
  final Map<String, Map<String, dynamic>> _currencies = {
    'MGA': {'name': 'Ariary', 'symbol': 'Ar', 'rate': 1.0},
    'USD': {'name': 'US Dollar', 'symbol': '\$', 'rate': 0.00022},
    'EUR': {'name': 'Euro', 'symbol': '€', 'rate': 0.00020},
    'GBP': {'name': 'British Pound', 'symbol': '£', 'rate': 0.00017},
  };

  String _convertedAmount = '';

  @override
  void initState() {
    super.initState();
    widget.priceController.addListener(_calculateConversion);
  }

  @override
  void dispose() {
    widget.priceController.removeListener(_calculateConversion);
    super.dispose();
  }

  void _calculateConversion() {
    final price = double.tryParse(widget.priceController.text);
    if (price == null || price == 0) {
      setState(() {
        _convertedAmount = '';
      });
      return;
    }

    final currentRate = _currencies[widget.selectedCurrency]!['rate'] as double;
    final conversions = <String>[];

    _currencies.forEach((code, data) {
      if (code != widget.selectedCurrency) {
        final rate = data['rate'] as double;
        final converted = (price * rate / currentRate);
        conversions
            .add('${data['symbol']} ${converted.toStringAsFixed(2)} $code');
      }
    });

    setState(() {
      _convertedAmount = conversions.join(' • ');
    });
  }

  void _showCurrencyPicker() {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Currency',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ..._currencies.entries.map((entry) {
              final isSelected = widget.selectedCurrency == entry.key;
              return ListTile(
                leading: Text(
                  entry.value['symbol'] as String,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                title: Text('${entry.value['name']} (${entry.key})'),
                trailing: isSelected
                    ? CustomIconWidget(
                        iconName: 'check_circle',
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      )
                    : null,
                onTap: () {
                  widget.onCurrencyChanged(entry.key);
                  Navigator.pop(context);
                },
              );
            }),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyData = _currencies[widget.selectedCurrency]!;

    return Container(
      padding: EdgeInsets.all(4.w),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Currency selector
              GestureDetector(
                onTap: _showCurrencyPicker,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Row(
                    children: [
                      Text(
                        currencyData['symbol'] as String,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        widget.selectedCurrency,
                        style: theme.textTheme.bodyMedium,
                      ),
                      SizedBox(width: 1.w),
                      CustomIconWidget(
                        iconName: 'arrow_drop_down',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              // Price input
              Expanded(
                child: TextFormField(
                  controller: widget.priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    hintText: '0.00',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Price is required';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Enter valid price';
                    }
                    return null;
                  },
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
            ],
          ),
          if (_convertedAmount.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info_outline',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      _convertedAmount,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
