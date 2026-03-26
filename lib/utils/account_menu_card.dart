import 'package:flutter/material.dart';
import 'theme.dart';

class AccountMenuCard extends StatelessWidget {
  final List<AccountMenuItemData> items;

  const AccountMenuCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
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
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.color),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: item.subtitle == null
                    ? null
                    : Text(
                        item.subtitle!,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textMuted,
                ),
                onTap: item.onTap,
              ),
              if (index < items.length - 1)
                const Divider(
                  height: 1,
                  indent: 76,
                  endIndent: 20,
                  color: AppTheme.borderLight,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class AccountMenuItemData {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const AccountMenuItemData({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.subtitle,
  });
}
