import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/entities/entities.dart';
import '../providers/sync_provider.dart';
import '../utils/account_section_card.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  Future<void> _openReviewEditor({Review? review}) async {
    final commentController = TextEditingController(text: review?.comment ?? '');
    int selectedRating = review?.rating ?? 4;
    int? productId = review?.productId;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review == null ? 'Create Review' : 'Edit Review',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (review == null)
                       TextField(
                        onChanged: (v) => productId = int.tryParse(v),
                        decoration: _inputDecoration('Product ID (Numeric)'),
                        keyboardType: TextInputType.number,
                      ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      decoration: _inputDecoration('Your comment'),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Rating',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          onPressed: () {
                            setModalState(() {
                              selectedRating = starValue;
                            });
                          },
                          icon: Icon(
                            starValue <= selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: AppTheme.accentOrange,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final comment = commentController.text.trim();
                          if (comment.isEmpty || (review == null && productId == null)) {
                            return;
                          }

                          final provider = context.read<SyncProvider>();
                          try {
                            if (review == null) {
                              await provider.addReview(productId!, selectedRating, comment);
                            } else {
                              await provider.updateReview(review.id, selectedRating, comment);
                            }
                            if (mounted) Navigator.pop(context, true);
                          } catch (e) {
                             if (mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text('Error: $e'))
                               );
                             }
                          }
                        },
                        child: Text(
                          review == null ? 'Save Review' : 'Update Review',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    commentController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncProvider = context.watch<SyncProvider>();
    final reviews = syncProvider.reviews;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ratings & Reviews'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          if (syncProvider.isSyncingReviews)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openReviewEditor,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Add Review'),
      ),
      body: RefreshIndicator(
        onRefresh: () => syncProvider.syncReviews(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AccountSectionCard(
              title: 'Your Product Reviews',
              subtitle: 'Manage your feedback, update comments, or remove reviews you no longer want to keep.',
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Reviews',
                      value: reviews.length.toString(),
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Avg. Rating',
                      value: reviews.isEmpty
                          ? '0.0'
                          : (reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length).toStringAsFixed(1),
                      color: AppTheme.accentOrange,
                    ),
                  ),
                ],
              ),
            ),
            if (reviews.isEmpty)
              AccountSectionCard(
                title: 'No Reviews Yet',
                subtitle: 'Share feedback on your favorite gadgets to help other shoppers.',
                child: SizedBox(
                  height: 140,
                  child: Center(
                    child: syncProvider.isSyncingReviews 
                      ? const CircularProgressIndicator()
                      : const Icon(
                          Icons.rate_review_outlined,
                          size: 60,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                ),
              )
            else
              AccountSectionCard(
                title: 'Review History',
                subtitle: 'Edit or delete any review from your account.',
                child: Column(
                  children: reviews
                      .map(
                        (review) => _buildReviewItem(syncProvider, review),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(SyncProvider provider, Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Product ID: ${review.productId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                DateFormat('dd MMM').format(review.updatedAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                size: 18,
                color: AppTheme.accentOrange,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            review.comment ?? 'No comment',
            style: const TextStyle(
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _openReviewEditor(review: review),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => provider.deleteReview(review.id),
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.accentRed,
                ),
                label: const Text(
                  'Delete',
                  style: TextStyle(
                    color: AppTheme.accentRed,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
    );
  }
}
