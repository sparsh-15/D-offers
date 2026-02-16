import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../models/offer_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/offer_banner_preview.dart';

/// Full-screen offer details: banner image, shop name, description, validity, like.
/// Used from customer (and optionally shopkeeper) when tapping an offer.
class OfferDetailScreen extends StatefulWidget {
  const OfferDetailScreen({
    super.key,
    required this.offer,
    this.onLikeChanged,
    this.onChatPressed,
  });

  final OfferModel offer;
  final VoidCallback? onLikeChanged;
  final VoidCallback? onChatPressed;

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  late bool _isLiked;
  late int _likesCount;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.offer.isLiked;
    _likesCount = widget.offer.likesCount;
  }

  Future<void> _toggleLike() async {
    if (_isToggling) return;
    setState(() {
      _isToggling = true;
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    try {
      final result = await AuthService.instance.toggleOfferLike(widget.offer.id);
      if (mounted) {
        setState(() {
          _isLiked = result['isLiked'] as bool;
          _likesCount = result['likesCount'] as int;
          _isToggling = false;
        });
        widget.onLikeChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? -1 : 1;
          _isToggling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeHelper.isDarkMode(context);
    final offer = widget.offer;

    String discountLabel;
    if (offer.discountType == 'percentage' && offer.discountValue != null) {
      discountLabel = '${offer.discountValue}% OFF';
    } else if (offer.discountType == 'fixed' && offer.discountValue != null) {
      discountLabel = '₹${offer.discountValue} OFF';
    } else {
      discountLabel = 'Offer';
    }

    final shopDisplayName = offer.shopName?.trim().isNotEmpty == true
        ? offer.shopName!
        : 'Local Shop';

    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (widget.onChatPressed != null)
              IconButton(
                icon: const Icon(Icons.chat_rounded),
                onPressed: widget.onChatPressed,
                tooltip: 'Help',
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OfferBannerPreview(
                  title: offer.title,
                  discountType: offer.discountType,
                  discountValue: offer.discountValue,
                  width: double.infinity,
                  height: 200,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.surface : AppColors.lightSurface).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.store_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shopDisplayName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Chip(
                      label: Text(
                        discountLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        offer.status.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      backgroundColor: offer.status == 'active'
                          ? AppColors.success
                          : (offer.status == 'expired' ? AppColors.error : AppColors.info),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _isToggling ? null : _toggleLike,
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : null,
                      ),
                    ),
                    Text(
                      '$_likesCount',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (offer.description.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          offer.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (offer.validFrom != null || offer.validTo != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Validity',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (offer.validFrom != null)
                            Expanded(
                              child: _ValidityChip(
                                label: 'From',
                                value: _formatDate(offer.validFrom!),
                                isDark: isDark,
                              ),
                            ),
                          if (offer.validFrom != null && offer.validTo != null)
                            const SizedBox(width: 12),
                          if (offer.validTo != null)
                            Expanded(
                              child: _ValidityChip(
                                label: 'To',
                                value: _formatDate(offer.validTo!),
                                isDark: isDark,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Show this offer at the store to redeem your discount.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _ValidityChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _ValidityChip({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
