import 'package:flutter/material.dart';
import '../utils/theme.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController searchController;
  final String? selectedCategory;
  final Function(String?) onCategoryChanged;
  final List<Map<String, dynamic>> categories;
  final Function(String)? onSearchChanged;

  const SearchBarWidget({
    super.key,
    required this.searchController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.categories,
    this.onSearchChanged,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: colors.searchBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.borderLight,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.search,
                  color: colors.textDisabled,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.searchController,
                    onChanged: widget.onSearchChanged,
                    style: TextStyle(color: colors.searchText),
                    decoration: InputDecoration(
                      hintText: 'Search products, brands...',
                      hintStyle: TextStyle(
                        color: colors.textDisabled,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                // Filter Button
                Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: colors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Filter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Category Chips
          _buildCategoryFilters(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final colors = AppTheme.colors(context);
          final category = widget.categories[index];
          final isSelected = widget.selectedCategory == category['name'] ||
              (widget.selectedCategory == null && category['name'] == 'All');

          return GestureDetector(
            onTap: () {
              widget.onCategoryChanged(isSelected ? null : category['name']);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : colors.secondarySurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : colors.borderLight,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (category['icon'] != null) ...[
                    Icon(
                      category['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : colors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    category['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
