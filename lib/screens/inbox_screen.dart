import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/account_menu_card.dart';
import '../utils/account_section_card.dart';
import '../utils/theme.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late final List<_InboxMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      _InboxMessage(
        title: 'Order confirmed',
        body:
            'Your latest Cyberspex order has been confirmed and is being prepared for dispatch.',
        category: 'Orders',
        timeLabel: '2h ago',
        icon: Icons.shopping_bag_outlined,
        color: AppTheme.primaryColor,
        unread: true,
      ),
      _InboxMessage(
        title: 'Flash deal reminder',
        body:
            'The gadgets in your wishlist are still part of this week\'s flash deals.',
        category: 'Promotions',
        timeLabel: 'Yesterday',
        icon: Icons.local_offer_outlined,
        color: AppTheme.accentOrange,
      ),
      _InboxMessage(
        title: 'Support reply available',
        body:
            'Customer service responded to your account setup question. Open the message to continue.',
        category: 'Support',
        timeLabel: '2 days ago',
        icon: Icons.support_agent_outlined,
        color: AppTheme.accentGreen,
        unread: true,
      ),
    ];
  }

  int get _unreadCount => _messages.where((message) => message.unread).length;

  void _markAllRead() {
    setState(() {
      for (final message in _messages) {
        message.unread = false;
      }
    });
  }

  void _toggleRead(_InboxMessage message) {
    setState(() {
      message.unread = !message.unread;
    });
  }

  void _archiveMessage(_InboxMessage message) {
    setState(() {
      _messages.remove(message);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${message.title} archived'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.currentUser?.name ?? 'Cyberspex Member';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Inbox'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          AccountSectionCard(
            title: 'Inbox & Notifications',
            subtitle:
                'Stay on top of orders, account activity, and support updates for $userName.',
            actions: [
              if (_messages.isNotEmpty)
                TextButton(
                  onPressed: _unreadCount == 0 ? null : _markAllRead,
                  child: const Text('Mark all read'),
                ),
            ],
            child: Row(
              children: [
                _buildSummaryChip(
                  icon: Icons.mark_email_unread_outlined,
                  label: 'Unread',
                  value: _unreadCount.toString(),
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                _buildSummaryChip(
                  icon: Icons.inbox_outlined,
                  label: 'Total',
                  value: _messages.length.toString(),
                  color: AppTheme.accentOrange,
                ),
              ],
            ),
          ),
          if (_messages.isEmpty)
            const AccountSectionCard(
              title: 'All Caught Up',
              subtitle:
                  'New order updates and support messages will appear here.',
              child: SizedBox(
                height: 120,
                child: Center(
                  child: Icon(
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
              subtitle:
                  'Tap a message to mark it read or unread. Swipe left to archive it.',
              child: Column(
                children: _messages
                    .map(
                      (message) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: ValueKey(message.title),
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
                          onDismissed: (_) => _archiveMessage(message),
                          child: _buildMessageTile(message),
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

  Widget _buildMessageTile(_InboxMessage message) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _toggleRead(message),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: message.unread
                ? message.color.withValues(alpha: 0.07)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: message.unread
                  ? message.color.withValues(alpha: 0.18)
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
                  color: message.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(message.icon, color: message.color),
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
                          message.timeLabel,
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
                              color: message.color,
                            ),
                          ),
                        ),
                        if (message.unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: message.color,
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
}

class _InboxMessage {
  final String title;
  final String body;
  final String category;
  final String timeLabel;
  final IconData icon;
  final Color color;
  bool unread;

  _InboxMessage({
    required this.title,
    required this.body,
    required this.category,
    required this.timeLabel,
    required this.icon,
    required this.color,
    this.unread = false,
  });
}
