import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
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
  bool _isSubmitting = false;

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

  Future<void> _submitTicket() async {
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

    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to submit a support ticket.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = authProvider.currentUser!.id;

      await supabase.from('support_tickets').insert({
        'user_id': userId,
        'topic': _selectedTopic,
        'message': message,
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Also create an inbox message for the user
      await supabase.from('inbox_messages').insert({
        'user_id': userId,
        'title': 'Support Ticket: $_selectedTopic',
        'body': 'Your support request has been received. We will get back to you soon.',
        'category': 'support',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      _messageController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support ticket submitted successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit ticket: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Customer Service'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Header Banner
          Container(
            margin: const EdgeInsets.all(16),
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
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Our support team is here to help you with any questions about your orders, products, or account.',
                  style: TextStyle(
                    height: 1.5,
                    color: Color(0xFFE6F0FF),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Quick Support Actions
          AccountSectionCard(
            title: 'Quick Support',
            subtitle: 'Choose how you want to reach us.',
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
                        label: 'Call Us',
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
                        label: 'Email',
                        icon: Icons.mail_outline,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        label: 'Inbox',
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

          // Submit Support Ticket
          AccountSectionCard(
            title: 'Submit a Support Ticket',
            subtitle: 'Send us a message and we\'ll respond within 24 hours.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topic Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedTopic,
                  decoration: InputDecoration(
                    labelText: 'Topic',
                    filled: true,
                    fillColor: const Color(0xFFF7FAFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    if (value != null) {
                      setState(() => _selectedTopic = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Message Text Field
                TextField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Describe your issue',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: const Color(0xFFF7FAFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitTicket,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(_isSubmitting ? 'Sending...' : 'Send Ticket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // FAQ Section
          AccountSectionCard(
            title: 'Frequently Asked Questions',
            subtitle: 'Quick answers to common questions.',
            child: Column(
              children: _faqItems
                  .map(
                    (faq) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
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
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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

          // Navigation Links
          AccountMenuCard(
            items: [
              AccountMenuItemData(
                icon: Icons.shopping_bag_outlined,
                title: 'My Orders',
                subtitle: 'View your order history',
                color: AppTheme.primaryColor,
                onTap: () => Navigator.pushNamed(context, '/orders'),
              ),
              AccountMenuItemData(
                icon: Icons.rate_review_outlined,
                title: 'Ratings & Reviews',
                subtitle: 'Manage your reviews',
                color: AppTheme.accentOrange,
                onTap: () => Navigator.pushNamed(context, '/reviews'),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap ?? () => _showContactAction(label),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 13,
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
