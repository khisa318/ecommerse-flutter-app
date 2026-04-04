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
    final theme = Theme.of(context);
    final colors = AppTheme.colors(context);

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                subtitle: item.subtitle == null
                    ? null
                    : Text(
                        item.subtitle!,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colors.textDisabled,
                ),
                onTap: item.onTap,
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  indent: 76,
                  endIndent: 20,
                  color: colors.borderLight,
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
