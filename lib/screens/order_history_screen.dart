import 'package:flutter/material.dart';
import '../models/order.dart';
import '../utils/currency.dart';
import '../utils/theme.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  // Mock orders data
  List<Order> get _mockOrders => [
        Order(
          id: 'ORD001',
          items: [], // Would be populated from cart items
          totalAmount: 1399.99,
          status: 'delivered',
          orderDate: DateTime.now().subtract(const Duration(days: 5)),
          shippingAddress: '123 Main St, City, Country',
          paymentMethod: 'Credit Card ****1234',
        ),
        Order(
          id: 'ORD002',
          items: [],
          totalAmount: 249.99,
          status: 'shipped',
          orderDate: DateTime.now().subtract(const Duration(days: 2)),
          shippingAddress: '123 Main St, City, Country',
          paymentMethod: 'PayPal',
        ),
        Order(
          id: 'ORD003',
          items: [],
          totalAmount: 99.99,
          status: 'pending',
          orderDate: DateTime.now().subtract(const Duration(hours: 12)),
          shippingAddress: '123 Main St, City, Country',
          paymentMethod: 'Credit Card ****1234',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: _mockOrders.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mockOrders.length,
              itemBuilder: (context, index) {
                return _buildOrderCard(_mockOrders[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 100,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 24),
          Text(
            'No orders yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    Color statusColor;
    switch (order.status) {
      case 'delivered':
        statusColor = AppTheme.accentGreen;
        break;
      case 'shipped':
        statusColor = AppTheme.primaryColor;
        break;
      case 'pending':
        statusColor = AppTheme.accentOrange;
        break;
      default:
        statusColor = AppTheme.textMuted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.borderLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ordered on ${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.shippingAddress,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.payment,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  order.paymentMethod,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatKsh(order.totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to order details
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
