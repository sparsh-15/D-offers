import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Renders a banner/logo style preview for an offer (title + discount).
/// Can be wrapped in RepaintBoundary and captured to image.
class OfferBannerPreview extends StatelessWidget {
  const OfferBannerPreview({
    super.key,
    required this.title,
    required this.discountType,
    this.discountValue,
    this.width = 320,
    this.height = 160,
  });

  final String title;
  final String discountType;
  final dynamic discountValue;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = discountValue != null &&
        (discountValue is num
            ? (discountValue as num).toString().isNotEmpty
            : discountValue.toString().trim().isNotEmpty);
    final discountStr = hasDiscount ? discountValue.toString() : '—';
    final suffix = discountType == 'percentage' ? '% OFF' : ' ₹ OFF';

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title.trim().isNotEmpty)
                    Text(
                      title.trim(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    const Text(
                      'Offer title',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hasDiscount ? '$discountStr$suffix' : 'Add discount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
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
