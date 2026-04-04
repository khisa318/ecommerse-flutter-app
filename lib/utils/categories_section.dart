import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CategoriesSection extends StatelessWidget {
  final List<Map<String, dynamic>> categories;

  const CategoriesSection({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryItem(context, category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(BuildContext context, Map<String, dynamic> category) {
    final colors = AppTheme.colors(context);
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: category['color'],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              category['icon'],
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category['name'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
