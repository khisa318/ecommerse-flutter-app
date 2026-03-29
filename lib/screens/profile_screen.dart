import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../utils/account_menu_card.dart';
import '../utils/cyberspex_branding.dart';
import '../utils/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromProvider();
    });
  }

  void _syncFromProvider() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || !mounted || _isEditing) return;

    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phone ?? '';
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Failed to update profile',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final navigator = Navigator.of(context);
    final authProvider = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await authProvider.logout();
              if (!mounted) return;
              navigator.pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                navigator.pushReplacementNamed('/main');
              });
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        if (user != null && !_isEditing) {
          _syncFromProvider();
        }

        if (authProvider.isRestoringSession) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F7FB),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.hasAuthenticatedSession && user == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F7FB),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sync_outlined,
                          size: 54,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Refreshing your profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Your account session is active. Tap below to finish loading your profile details.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            height: 1.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => authProvider.checkAuthStatus(),
                            child: const Text('Reload Profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (!authProvider.isLoggedIn) {
          return _buildLoggedOutState(context);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => Provider.of<SyncProvider>(context, listen: false).syncAll(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildProfileHeader(authProvider),
                  ),
                  SliverToBoxAdapter(
                    child: Consumer<SyncProvider>(
                      builder: (context, sync, child) => _buildStatsSection(sync),
                    ),
                  ),
                  if (_isEditing)
                    SliverToBoxAdapter(
                      child: _buildEditSection(authProvider),
                    ),
                  SliverToBoxAdapter(
                    child: _buildMenuSection(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoggedOutState(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CyberspexWordmark(),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome To Your Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Login to manage your profile, saved gadgets, and support options.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signup'),
                        child: const Text('Create Account'),
                      ),
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

  Widget _buildProfileHeader(AuthProvider authProvider) {
    final user = authProvider.currentUser!;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
    final syncProvider = context.watch<SyncProvider>();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F2E67),
            AppTheme.primaryColor,
            Color(0xFF0EA5E9),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: CyberspexWordmark(
                  titleColor: Colors.white,
                  subtitleColor: Color(0xFFD9E9FF),
                  compact: true,
                ),
              ),
              if (syncProvider.isSyncingInbox || syncProvider.isSyncingOrders || syncProvider.isSyncingReviews)
                 const Padding(
                   padding: EdgeInsets.only(right: 8.0),
                   child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                 ),
              IconButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () {
                        setState(() {
                          _isEditing = !_isEditing;
                          if (!_isEditing) {
                            _syncFromProvider();
                          }
                        });
                      },
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit_outlined,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _isEditing ? 'Editing profile' : 'Cyberspex member',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(SyncProvider sync) {
    final unreadCount = sync.inboxMessages.where((m) => !m.isRead).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(sync.orders.length.toString(), 'Orders'),
          Container(
            width: 1,
            height: 44,
            color: AppTheme.borderLight,
          ),
          _buildStatItem(unreadCount.toString(), 'Inbox'),
          Container(
            width: 1,
            height: 44,
            color: AppTheme.borderLight,
          ),
          _buildStatItem(sync.reviews.length.toString(), 'Reviews'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEditSection(AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Simple Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : _saveProfile,
              child: authProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: const Color(0xFFF7FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    final sync = context.watch<SyncProvider>();
    final unreadCount = sync.inboxMessages.where((m) => !m.isRead).length;

    return AccountMenuCard(
      items: [
        AccountMenuItemData(
          icon: Icons.shopping_bag_outlined,
          title: 'Orders',
          color: AppTheme.primaryColor,
          onTap: () => Navigator.pushNamed(context, '/orders'),
        ),
        AccountMenuItemData(
          icon: Icons.mail_outline,
          title: 'Inbox',
          subtitle: unreadCount > 0 ? '$unreadCount unread' : null,
          color: AppTheme.accentOrange,
          onTap: () => Navigator.pushNamed(context, '/inbox'),
        ),
        AccountMenuItemData(
          icon: Icons.rate_review_outlined,
          title: 'Ratings & Reviews',
          color: AppTheme.accentGreen,
          onTap: () => Navigator.pushNamed(context, '/reviews'),
        ),
        AccountMenuItemData(
          icon: Icons.favorite_border,
          title: 'Wishlist',
          color: const Color(0xFF8B5CF6),
          onTap: () => Navigator.pushNamed(context, '/wishlist'),
        ),
        AccountMenuItemData(
          icon: Icons.support_agent_outlined,
          title: 'Customer Service',
          color: const Color(0xFF0EA5E9),
          onTap: () => Navigator.pushNamed(context, '/customer-service'),
        ),
        AccountMenuItemData(
          icon: Icons.logout,
          title: 'Logout',
          color: AppTheme.accentRed,
          onTap: _handleLogout,
        ),
      ],
    );
  }
}
