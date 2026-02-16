import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/offer_model.dart';
import '../screens/common/offer_detail_screen.dart';
import '../screens/customer/customer_chat_bot_screen.dart';
import '../services/auth_service.dart';
import '../core/utils/dialog_helper.dart';
import 'offer_banner_preview.dart';

class OfferCard extends StatefulWidget {
  final OfferModel offer;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showLikes;
  final VoidCallback? onLikeChanged;
  /// When true, tapping the card opens the offer detail screen (customer flow).
  final bool openDetailOnTap;

  const OfferCard({
    super.key,
    required this.offer,
    this.onTap,
    this.trailing,
    this.showLikes = true,
    this.onLikeChanged,
    this.openDetailOnTap = true,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likesCount;
  bool _isToggling = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.offer.isLiked;
    _likesCount = widget.offer.likesCount;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(OfferCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offer.id != widget.offer.id ||
        oldWidget.offer.isLiked != widget.offer.isLiked ||
        oldWidget.offer.likesCount != widget.offer.likesCount) {
      _isLiked = widget.offer.isLiked;
      _likesCount = widget.offer.likesCount;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_isToggling) return;

    setState(() {
      _isToggling = true;
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    try {
      final result = await AuthService.instance.toggleOfferLike(widget.offer.id);
      setState(() {
        _isLiked = result['isLiked'] as bool;
        _likesCount = result['likesCount'] as int;
        _isToggling = false;
      });
      widget.onLikeChanged?.call();
    } catch (e) {
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? -1 : 1;
        _isToggling = false;
      });
      if (mounted) {
        DialogHelper.showErrorSnackBar(context, 'Failed to update like: $e');
      }
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    if (widget.openDetailOnTap) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OfferDetailScreen(
            offer: widget.offer,
            onLikeChanged: widget.onLikeChanged,
            onChatPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CustomerChatBotScreen(),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String discountLabel;
    if (widget.offer.discountType == 'percentage' && widget.offer.discountValue != null) {
      discountLabel = '${widget.offer.discountValue}% OFF';
    } else if (widget.offer.discountType == 'fixed' && widget.offer.discountValue != null) {
      discountLabel = '₹${widget.offer.discountValue} OFF';
    } else {
      discountLabel = 'Offer';
    }

    Color statusColor;
    switch (widget.offer.status) {
      case 'inactive':
        statusColor = AppColors.info;
        break;
      case 'expired':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.success;
    }

    final shopDisplayName = widget.offer.shopName?.trim().isNotEmpty == true
        ? widget.offer.shopName!
        : 'Shop';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _handleTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OfferBannerPreview(
              title: widget.offer.title,
              discountType: widget.offer.discountType,
              discountValue: widget.offer.discountValue,
              width: double.infinity,
              height: 140,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.store_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          shopDisplayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.trailing != null)
                        widget.trailing!
                      else if (widget.showLikes)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: IconButton(
                                icon: Icon(
                                  _isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: _isLiked ? Colors.red : (isDark ? Colors.grey : Colors.grey[600]),
                                  size: 22,
                                ),
                                onPressed: _toggleLike,
                                tooltip: _isLiked ? 'Unlike' : 'Like',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ),
                            Text(
                              '$_likesCount',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(
                          discountLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      ),
                      Chip(
                        label: Text(
                          widget.offer.status.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        backgroundColor: statusColor,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
