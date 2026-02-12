import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/offer_model.dart';

class OfferCard extends StatelessWidget {
  final OfferModel offer;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showLikes;

  const OfferCard({
    super.key,
    required this.offer,
    this.onTap,
    this.trailing,
    this.showLikes = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String discountLabel;
    if (offer.discountType == 'percentage' && offer.discountValue != null) {
      discountLabel = '${offer.discountValue}% OFF';
    } else if (offer.discountType == 'fixed' && offer.discountValue != null) {
      discountLabel = '₹${offer.discountValue} OFF';
    } else {
      discountLabel = 'Offer';
    }

    Color statusColor;
    switch (offer.status) {
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
      child: InkWell(
        onTap: onTap,
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
                          offer.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (offer.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              offer.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
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
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(
                      offer.status.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: statusColor,
                    visualDensity: VisualDensity.compact,
                  ),
                  if (showLikes)
                    Chip(
                      label: Text(
                        '❤️ ${offer.likesCount}',
                        style: const TextStyle(color: Colors.white),
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

