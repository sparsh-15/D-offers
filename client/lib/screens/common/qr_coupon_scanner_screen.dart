import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';

class QrCouponScannerScreen extends StatefulWidget {
  const QrCouponScannerScreen({super.key});

  @override
  State<QrCouponScannerScreen> createState() => _QrCouponScannerScreenState();
}

class _QrCouponScannerScreenState extends State<QrCouponScannerScreen> {
  late final MobileScannerController _controller;
  bool _torchEnabled = false;
  bool _scanHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanHandled) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        _scanHandled = true;
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Column(
            children: [
              Container(
                color: AppColors.black.withValues(alpha: 0.64),
                padding: const EdgeInsets.only(
                  top: 52,
                  left: AppTokens.spaceMD,
                  right: AppTokens.spaceMD,
                  bottom: AppTokens.spaceMD,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Scan Coupon QR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: AppTokens.fontTitleMD,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await _controller.toggleTorch();
                        if (!mounted) return;
                        setState(() => _torchEnabled = !_torchEnabled);
                      },
                      icon: Icon(
                        _torchEnabled
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: Container(
                            color: AppColors.black.withValues(alpha: 0.62),
                          ),
                        ),
                        SizedBox(
                          height: 260,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  color:
                                      AppColors.black.withValues(alpha: 0.62),
                                ),
                              ),
                              Container(
                                width: 260,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(AppTokens.radiusMD),
                                  border: Border.all(
                                    color: AppColors.accent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  color:
                                      AppColors.black.withValues(alpha: 0.62),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: AppColors.black.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 40,
                      child: Column(
                        children: const [
                          Text(
                            'Align the coupon QR inside the frame',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: AppTokens.fontBodyLG,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppTokens.spaceXS),
                          Text(
                            'Code will auto-fill after scan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.white70,
                              fontSize: AppTokens.fontBodySM,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
