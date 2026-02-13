import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/offer_model.dart';
import '../services/auth_service.dart';
import '../core/utils/dialog_helper.dart';

class OfferCard extends StatefulWidget {
  final OfferModel offer;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showLikes;
  final VoidCallback? onLikeChanged;

  const OfferCard({
    super.key,
    required this.offer,
    this.onTap,
    this.trailing,
    this.showLikes = true,
    this.onLikeChanged,
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
      if (widget.onLikeChanged != null) {
        widget.onLikeChanged!();
      }
    } catch (e) {
      // Revert on error
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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_offer_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.offer.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (widget.offer.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              widget.offer.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.trailing != null) 
                    widget.trailing!
                  else
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : (isDark ? Colors.grey : Colors.grey[600]),
                        ),
                        onPressed: _toggleLike,
                        tooltip: _isLiked ? 'Unlike' : 'Like',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(
                      discountLabel,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(
                      widget.offer.status.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: statusColor,
                    visualDensity: VisualDensity.compact,
                  ),
                  if (widget.showLikes)
                    Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_likesCount',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      backgroundColor:
                          isDark ? AppColors.surface : AppColors.accent,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

