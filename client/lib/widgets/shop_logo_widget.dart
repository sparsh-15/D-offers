import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class ShopLogoWidget extends StatelessWidget {
  const ShopLogoWidget({
    super.key,
    this.logoUrl,
    required this.radius,
    this.onTap,
    this.isEditable = false,
  });

  final String? logoUrl;
  final double radius;
  final VoidCallback? onTap;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.trim().isNotEmpty;
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: ClipOval(
        child: hasLogo
            ? CachedNetworkImage(
                imageUrl: logoUrl!.trim(),
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (_, __) => SizedBox(
                  width: radius,
                  height: radius,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Icon(
                  Icons.store_rounded,
                  size: radius,
                  color: AppColors.white,
                ),
              )
            : Icon(
                Icons.store_rounded,
                size: radius,
                color: AppColors.white,
              ),
      ),
    );

    final content = isEditable
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    size: 14,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          )
        : avatar;

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: content,
    );
  }
}