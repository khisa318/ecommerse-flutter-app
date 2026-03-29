import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../domain/entities/entities.dart';
import '../utils/account_menu_card.dart';
import '../utils/account_section_card.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final syncProvider = context.watch<SyncProvider>();
    final userName = authProvider.currentUser?.name ?? 'Cyberspex Member';
    final messages = syncProvider.inboxMessages;
    final unreadCount = messages.where((m) => !m.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Inbox'),
        backgroundColor: Colors.white,
        actions: [
          if (syncProvider.isSyncingInbox)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => syncProvider.syncInbox(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AccountSectionCard(
              title: 'Inbox & Notifications',
              subtitle: 'Stay on top of orders, account activity, and support updates for $userName.',
              actions: [
                if (messages.isNotEmpty && unreadCount > 0)
                  TextButton(
                    onPressed: () {
                      // Implementation for mark all read if needed
                    },
                    child: const Text('Mark all read'),
                  ),
              ],
              child: Row(
                children: [
                  _buildSummaryChip(
                    icon: Icons.mark_email_unread_outlined,
                    label: 'Unread',
                    value: unreadCount.toString(),
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryChip(
                    icon: Icons.inbox_outlined,
                    label: 'Total',
                    value: messages.length.toString(),
                    color: AppTheme.accentOrange,
                  ),
                ],
              ),
            ),
            if (messages.isEmpty)
              AccountSectionCard(
                title: 'All Caught Up',
                subtitle: 'New order updates and support messages will appear here.',
                child: SizedBox(
                  height: 120,
                  child: Center(
                    child: syncProvider.isSyncingInbox 
                      ? const CircularProgressIndicator()
                      : const Icon(
                          Icons.mark_email_read_outlined,
                          size: 60,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                ),
              )
            else
              AccountSectionCard(
                title: 'Recent Messages',
                subtitle: 'Tap a message to mark it read. Swipe left to archive it.',
                child: Column(
                  children: messages
                      .map(
                        (message) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: ValueKey(message.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: AppTheme.accentRed,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.archive_outlined,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) {
                              // Archive implementation or delete
                            },
                            child: _buildMessageTile(context, syncProvider, message),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            AccountMenuCard(
              items: [
                AccountMenuItemData(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Open Orders',
                  subtitle: 'Jump back to your order history',
                  color: AppTheme.primaryColor,
                  onTap: () => Navigator.pushNamed(context, '/orders'),
                ),
                AccountMenuItemData(
                  icon: Icons.favorite_border,
                  title: 'Go To Wishlist',
                  subtitle: 'Check products you saved for later',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.pushNamed(context, '/wishlist'),
                ),
                AccountMenuItemData(
                  icon: Icons.support_agent_outlined,
                  title: 'Customer Service',
                  subtitle: 'Continue the conversation with support',
                  color: AppTheme.accentGreen,
                  onTap: () => Navigator.pushNamed(context, '/customer-service'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTile(BuildContext context, SyncProvider provider, InboxMessage message) {
    final color = _getCategoryColor(message.category);
    final icon = _getCategoryIcon(message.category);
    final timeLabel = _formatDateTime(message.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (!message.isRead) {
             provider.markInboxRead(message.id);
          }
        },
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: !message.isRead
                ? color.withValues(alpha: 0.07)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: !message.isRead
                  ? color.withValues(alpha: 0.18)
                  : AppTheme.borderLight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message.body,
                      style: const TextStyle(
                        height: 1.45,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            message.category,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        if (!message.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'orders': return AppTheme.primaryColor;
      case 'promotions': return AppTheme.accentOrange;
      case 'support': return AppTheme.accentGreen;
      default: return AppTheme.primaryLight;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'orders': return Icons.shopping_bag_outlined;
      case 'promotions': return Icons.local_offer_outlined;
      case 'support': return Icons.support_agent_outlined;
      default: return Icons.notifications_none_outlined;
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd/MM').format(dt);
  }
}

