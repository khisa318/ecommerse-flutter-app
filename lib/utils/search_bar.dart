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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: widget.searchController,
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 15,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textMuted,
                  size: 22,
                ),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryFilters(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final isSelected = widget.selectedCategory == category['name'] ||
              (widget.selectedCategory == null && category['name'] == 'All');

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(category['name']),
              selected: isSelected,
              onSelected: (selected) {
                widget.onCategoryChanged(selected ? category['name'] : null);
              },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color:
                    isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected ? AppTheme.primaryColor : AppTheme.borderLight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
