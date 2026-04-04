import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/entities/entities.dart' as entities;
import '../providers/sync_provider.dart';
import '../utils/currency.dart';
import '../utils/theme.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final syncProvider = context.watch<SyncProvider>();
    final orders = syncProvider.orders;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          if (syncProvider.isSyncingOrders)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => syncProvider.syncOrders(force: true),
        child: orders.isEmpty
            ? _buildEmptyState(context, syncProvider.isSyncingOrders)
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  return _buildOrderCard(orders[index]);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isLoading) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const CircularProgressIndicator()
          else ...[
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
          ]
        ],
      ),
    );
  }

  Widget _buildOrderCard(entities.Order order) {
    Color statusColor;
    switch (order.status.toLowerCase()) {
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
              'Ordered on ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${order.items.length} items',
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatKsh((order.totalPrice / 100).toDouble()),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to order details if there was a detail screen
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
