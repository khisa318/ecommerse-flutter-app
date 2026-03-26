import 'package:flutter/material.dart';
import '../utils/account_menu_card.dart';
import '../utils/account_section_card.dart';
import '../utils/theme.dart';

class CustomerServiceScreen extends StatefulWidget {
  const CustomerServiceScreen({super.key});

  @override
  State<CustomerServiceScreen> createState() => _CustomerServiceScreenState();
}

class _CustomerServiceScreenState extends State<CustomerServiceScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _selectedTopic = 'Orders';

  final List<String> _topics = const [
    'Orders',
    'Delivery',
    'Payments',
    'Account',
    'Warranty',
  ];

  final List<_FaqItem> _faqItems = const [
    _FaqItem(
      question: 'How long does delivery take?',
      answer:
          'Standard delivery usually takes 2 to 5 business days depending on your location and the product type.',
    ),
    _FaqItem(
      question: 'Can I edit my profile after signup?',
      answer:
          'Yes. Open your profile page, tap edit, update your details, and save your changes.',
    ),
    _FaqItem(
      question: 'How do I track an order?',
      answer:
          'Open Orders from your profile menu to check current order status and progress.',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitTicket() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a short message for support first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Support request sent for $_selectedTopic.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showContactAction(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '$label is ready to be connected to your live support channel.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Customer Service'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2E67),
                  AppTheme.primaryColor,
                  AppTheme.primaryLight,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help Fast?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Reach Cyberspex support for account setup, order guidance, and product help in one place.',
                  style: TextStyle(
                    height: 1.5,
                    color: Color(0xFFE6F0FF),
                  ),
                ),
              ],
            ),
          ),
          AccountSectionCard(
            title: 'Quick Support',
            subtitle: 'Choose the support path that fits your issue best.',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: 'Live Chat',
                        icon: Icons.chat_bubble_outline,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        label: 'Call Support',
                        icon: Icons.call_outlined,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: 'Email Help',
                        icon: Icons.mail_outline,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        label: 'Open Inbox',
                        icon: Icons.inbox_outlined,
                        color: const Color(0xFF8B5CF6),
                        onTap: () => Navigator.pushNamed(context, '/inbox'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AccountSectionCard(
            title: 'Submit A Support Ticket',
            subtitle:
                'Leave a message and keep a record of the issue for follow-up.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedTopic,
                  decoration: InputDecoration(
                    labelText: 'Help topic',
                    filled: true,
                    fillColor: const Color(0xFFF7FAFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _topics
                      .map(
                        (topic) => DropdownMenuItem(
                          value: topic,
                          child: Text(topic),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedTopic = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Describe your issue',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: const Color(0xFFF7FAFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitTicket,
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Send Ticket'),
                  ),
                ),
              ],
            ),
          ),
          AccountSectionCard(
            title: 'Frequently Asked Questions',
            subtitle:
                'Quick answers for the most common account and shopping issues.',
            child: Column(
              children: _faqItems
                  .map(
                    (faq) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(
                          faq.question,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              faq.answer,
                              style: const TextStyle(
                                height: 1.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
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
                title: 'My Orders',
                subtitle: 'Review active and completed orders',
                color: AppTheme.primaryColor,
                onTap: () => Navigator.pushNamed(context, '/orders'),
              ),
              AccountMenuItemData(
                icon: Icons.rate_review_outlined,
                title: 'Ratings & Reviews',
                subtitle: 'Manage product feedback you have left',
                color: AppTheme.accentOrange,
                onTap: () => Navigator.pushNamed(context, '/reviews'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap ?? () => _showContactAction(label),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });
}
