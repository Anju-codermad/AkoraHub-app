
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/order_card_widget.dart';
import './widgets/order_detail_sheet_widget.dart';
import './widgets/order_search_widget.dart';
import './widgets/order_status_filter_widget.dart';

/// Order Management Screen
/// Enables business owners to track, process, and fulfill customer orders
class OrderManagement extends StatefulWidget {
  const OrderManagement({super.key});

  @override
  State<OrderManagement> createState() => _OrderManagementState();
}

class _OrderManagementState extends State<OrderManagement> {
  String _selectedStatus = 'All';
  String _searchQuery = '';
  bool _isRefreshing = false;
  DateTimeRange? _selectedDateRange;

  final List<Map<String, dynamic>> _orders = [
    {
      "orderId": "ORD-2025-001",
      "customerName": "Jean Rakoto",
      "customerEmail": "jean.rakoto@email.mg",
      "customerPhone": "+261 34 12 345 67",
      "orderDate": "2025-12-08",
      "totalAmount": "\$245.50",
      "status": "Pending",
      "paymentStatus": "Pending",
      "products": [
        {
          "name": "Natural Soap Bar - Lavender",
          "quantity": 5,
          "price": "\$45.00",
          "image":
              "https://images.unsplash.com/photo-1622116578641-dd2260fb7156",
          "semanticLabel":
              "Purple lavender soap bars stacked on white marble surface with dried lavender sprigs"
        },
        {
          "name": "Organic Shampoo 500ml",
          "quantity": 3,
          "price": "\$120.00",
          "image":
              "https://img.rocket.new/generatedImages/rocket_gen_img_196b445bb-1764778043502.png",
          "semanticLabel":
              "Clear glass bottle of organic shampoo with green pump dispenser on bathroom shelf"
        },
        {
          "name": "Hand Sanitizer Gel 250ml",
          "quantity": 2,
          "price": "\$80.50",
          "image":
              "https://images.unsplash.com/photo-1608564348103-2b78891150cf",
          "semanticLabel":
              "White plastic bottle of hand sanitizer gel with blue label on clean white background"
        }
      ]
    },
    {
      "orderId": "ORD-2025-002",
      "customerName": "Marie Rasoamanarivo",
      "customerEmail": "marie.r@email.mg",
      "customerPhone": "+261 33 98 765 43",
      "orderDate": "2025-12-07",
      "totalAmount": "\$180.00",
      "status": "Processing",
      "paymentStatus": "Completed",
      "products": [
        {
          "name": "Facial Cleanser 200ml",
          "quantity": 4,
          "price": "\$180.00",
          "image":
              "https://images.unsplash.com/photo-1670832218022-d393cb5843c2",
          "semanticLabel":
              "White tube of facial cleanser with silver cap on pink background with water droplets"
        }
      ]
    },
    {
      "orderId": "ORD-2025-003",
      "customerName": "Paul Andrianina",
      "customerEmail": "paul.a@email.mg",
      "customerPhone": "+261 32 55 123 45",
      "orderDate": "2025-12-06",
      "totalAmount": "\$520.00",
      "status": "Completed",
      "paymentStatus": "Completed",
      "products": [
        {
          "name": "Luxury Soap Gift Set",
          "quantity": 2,
          "price": "\$320.00",
          "image":
              "https://images.unsplash.com/photo-1668772386446-7029b0cc8776",
          "semanticLabel":
              "Elegant gift box containing assorted colorful handmade soaps wrapped in tissue paper"
        },
        {
          "name": "Body Lotion 500ml",
          "quantity": 4,
          "price": "\$200.00",
          "image":
              "https://images.unsplash.com/photo-1595458035461-2c8679a1eb74",
          "semanticLabel":
              "White pump bottle of body lotion on wooden surface with green plant leaves"
        }
      ]
    },
    {
      "orderId": "ORD-2025-004",
      "customerName": "Sophie Raharison",
      "customerEmail": "sophie.r@email.mg",
      "customerPhone": "+261 34 88 999 00",
      "orderDate": "2025-12-05",
      "totalAmount": "\$95.00",
      "status": "Cancelled",
      "paymentStatus": "Failed",
      "products": [
        {
          "name": "Antibacterial Soap 100g",
          "quantity": 5,
          "price": "\$95.00",
          "image":
              "https://img.rocket.new/generatedImages/rocket_gen_img_1a9cf1ebd-1764731114409.png",
          "semanticLabel":
              "White antibacterial soap bar with blue packaging on clean bathroom counter"
        }
      ]
    },
    {
      "orderId": "ORD-2025-005",
      "customerName": "David Randria",
      "customerEmail": "david.r@email.mg",
      "customerPhone": "+261 33 44 555 66",
      "orderDate": "2025-12-04",
      "totalAmount": "\$340.00",
      "status": "Processing",
      "paymentStatus": "Completed",
      "products": [
        {
          "name": "Hair Conditioner 500ml",
          "quantity": 3,
          "price": "\$150.00",
          "image":
              "https://img.rocket.new/generatedImages/rocket_gen_img_11320194f-1764666517604.png",
          "semanticLabel":
              "Brown glass bottle of hair conditioner with gold pump on marble bathroom shelf"
        },
        {
          "name": "Moisturizing Cream 250ml",
          "quantity": 2,
          "price": "\$190.00",
          "image":
              "https://images.unsplash.com/photo-1681810908966-e8f8265c1743",
          "semanticLabel":
              "White jar of moisturizing cream with silver lid on pink background with flower petals"
        }
      ]
    },
    {
      "orderId": "ORD-2025-006",
      "customerName": "Nathalie Razafindrakoto",
      "customerEmail": "nathalie.r@email.mg",
      "customerPhone": "+261 32 77 888 99",
      "orderDate": "2025-12-03",
      "totalAmount": "\$420.00",
      "status": "Completed",
      "paymentStatus": "Completed",
      "products": [
        {
          "name": "Organic Body Wash 1L",
          "quantity": 6,
          "price": "\$420.00",
          "image":
              "https://images.unsplash.com/photo-1648745318050-ec40e25bdada",
          "semanticLabel":
              "Clear plastic bottle of organic body wash with green label in modern shower"
        }
      ]
    }
  ];

  Map<String, int> get _statusCounts {
    final counts = <String, int>{
      'All': _orders.length,
      'Pending': 0,
      'Processing': 0,
      'Completed': 0,
      'Cancelled': 0,
    };

    for (final order in _orders) {
      final status = order['status'] as String? ?? 'Pending';
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }

  List<Map<String, dynamic>> get _filteredOrders {
    var filtered = _orders;

    if (_selectedStatus != 'All') {
      filtered = filtered
          .where((order) => order['status'] == _selectedStatus)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        final orderId = (order['orderId'] as String? ?? '').toLowerCase();
        final customerName =
            (order['customerName'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return orderId.contains(query) || customerName.contains(query);
      }).toList();
    }

    if (_selectedDateRange != null) {
      filtered = filtered.where((order) {
        final orderDate =
            DateTime.tryParse(order['orderDate'] as String? ?? '');
        if (orderDate == null) return false;
        return orderDate.isAfter(
                _selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            orderDate
                .isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isRefreshing = false);
    Fluttertoast.showToast(
      msg: "Orders synced successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleStatusUpdate(Map<String, dynamic> order, String newStatus) {
    setState(() {
      order['status'] = newStatus;
    });
    Fluttertoast.showToast(
      msg: "Order status updated to $newStatus",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleContactCustomer(Map<String, dynamic> order) {
    Navigator.pushNamed(context, '/messaging-center', arguments: {
      'customerName': order['customerName'],
      'customerEmail': order['customerEmail'],
    });
  }

  Future<void> _handleGenerateInvoice(Map<String, dynamic> order) async {
    try {
      final pdf = pw.Document();
      final products = (order['products'] as List?) ?? [];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                      fontSize: 32, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Order ID: ${order['orderId']}'),
                pw.Text('Date: ${order['orderDate']}'),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Customer Information',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Name: ${order['customerName']}'),
                pw.Text('Email: ${order['customerEmail']}'),
                pw.Text('Phone: ${order['customerPhone']}'),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Products',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['Product', 'Quantity', 'Price'],
                  data: products
                      .map((product) => [
                            product['name'],
                            product['quantity'].toString(),
                            product['price'],
                          ])
                      .toList(),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Amount',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      order['totalAmount'] as String,
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      Fluttertoast.showToast(
        msg: "Invoice generated successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to generate invoice",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => OrderDetailSheetWidget(
          order: order,
          onGenerateInvoice: () {
            Navigator.pop(context);
            _handleGenerateInvoice(order);
          },
          onContactCustomer: () {
            Navigator.pop(context);
            _handleContactCustomer(order);
          },
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Orders',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: CustomIconWidget(
                  iconName: Icons.date_range.codePoint.toRadixString(16),
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Date Range'),
                subtitle: _selectedDateRange != null
                    ? Text(
                        '${_selectedDateRange!.start.toString().split(' ')[0]} - ${_selectedDateRange!.end.toString().split(' ')[0]}')
                    : const Text('Select date range'),
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _selectedDateRange,
                  );
                  if (range != null) {
                    setState(() => _selectedDateRange = range);
                    Navigator.pop(context);
                  }
                },
              ),
              if (_selectedDateRange != null)
                ListTile(
                  leading: CustomIconWidget(
                    iconName: Icons.clear.codePoint.toRadixString(16),
                    color: theme.colorScheme.error,
                    size: 24,
                  ),
                  title: const Text('Clear Date Filter'),
                  onTap: () {
                    setState(() => _selectedDateRange = null);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: Icons.arrow_back.codePoint.toRadixString(16),
            color: theme.appBarTheme.foregroundColor ??
                theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order Management',
          style: theme.appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName:
                  Icons.notifications_outlined.codePoint.toRadixString(16),
              color: theme.appBarTheme.foregroundColor ??
                  theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () => Navigator.pushNamed(context, '/messaging-center'),
          ),
        ],
      ),
      body: Column(
        children: [
          OrderStatusFilterWidget(
            selectedStatus: _selectedStatus,
            onStatusChanged: (status) =>
                setState(() => _selectedStatus = status),
            statusCounts: _statusCounts,
          ),
          OrderSearchWidget(
            onSearch: (query) => setState(() => _searchQuery = query),
            onFilterTap: _showFilterSheet,
          ),
          Expanded(
            child: _isRefreshing
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: Icons.inbox_outlined.codePoint
                                  .toRadixString(16),
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No orders found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _handleRefresh,
                        color: theme.colorScheme.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            return OrderCardWidget(
                              order: order,
                              onTap: () => _showOrderDetail(order),
                              onUpdateStatus: (status) =>
                                  _handleStatusUpdate(order, status),
                              onContactCustomer: () =>
                                  _handleContactCustomer(order),
                              onGenerateInvoice: () =>
                                  _handleGenerateInvoice(order),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
