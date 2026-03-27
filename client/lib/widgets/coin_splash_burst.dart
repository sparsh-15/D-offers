import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class CoinSplashBurst extends StatefulWidget {
  const CoinSplashBurst({
    super.key,
    required this.amount,
    required this.isDebit,
    this.onCompleted,
  });

  final int amount;
  final bool isDebit;
  final VoidCallback? onCompleted;

  @override
  State<CoinSplashBurst> createState() => _CoinSplashBurstState();
}

class _CoinSplashBurstState extends State<CoinSplashBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _lift = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _lift = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.isDebit ? AppColors.error : AppColors.accent;
    final String signedAmount =
        '${widget.isDebit ? '-' : '+'}${widget.amount.clamp(0, 999999)}';

    return SizedBox(
      width: 120,
      height: 90,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CoinBurstPainter(
              progress: _controller.value,
              color: accent,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 680),
                  curve: Curves.easeOutCubic,
                  bottom: _lift ? 48 : 10,
                  right: 6,
                  child: Opacity(
                    opacity: (1 - _controller.value).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.86 + (_controller.value * 0.22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: accent, width: 0.9),
                        ),
                        child: Text(
                          signedAmount,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CoinBurstPainter extends CustomPainter {
  _CoinBurstPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color =
          color.withValues(alpha: (0.8 - (progress * 0.8)).clamp(0.0, 1.0));

    final Offset center = Offset(size.width - 28, size.height - 34);
    const int particleCount = 12;

    for (int i = 0; i < particleCount; i++) {
      final double t = i / particleCount;
      final double angle = (math.pi * 2 * t) - (math.pi / 3);
      final double radius = 8 + (progress * 26);
      final double driftY = progress * 18;

      final Offset p = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius - driftY,
      );

      final double r = 1.5 + ((1 - progress) * 2.2);
      canvas.drawCircle(p, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CoinBurstPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
