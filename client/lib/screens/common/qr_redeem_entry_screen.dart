import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/qr_payload_parser.dart';
import '../../core/utils/theme_helper.dart';
import '../../models/offer_model.dart';
import '../../models/redemption_model.dart';
import '../../services/auth_service.dart';
import '../../services/redemption_service.dart';
import '../../widgets/data_state_wrapper.dart';
import 'qr_coupon_scanner_screen.dart';
import 'redemption_history_screen.dart';

enum RedemptionInputMode { qr, manual }

class QrRedeemEntryScreen extends StatefulWidget {
  const QrRedeemEntryScreen({super.key});

  @override
  State<QrRedeemEntryScreen> createState() => _QrRedeemEntryScreenState();
}

class _QrRedeemEntryScreenState extends State<QrRedeemEntryScreen> {
  final TextEditingController _couponController = TextEditingController();

  final List<OfferModel> _offers = [];
  bool _loadingOffers = true;
  String? _offersError;

  String? _selectedOfferId;
  RedemptionInputMode _mode = RedemptionInputMode.qr;

  bool _submitting = false;
  RedemptionResponse? _lastResponse;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _loadingOffers = true;
      _offersError = null;
    });

    try {
      final offers = await AuthService.instance.getShopkeeperOffers();
      final activeOffers = offers.where((o) => o.status == 'active').toList();

      if (!mounted) return;
      setState(() {
        _offers
          ..clear()
          ..addAll(activeOffers);
        _selectedOfferId = activeOffers.isEmpty ? null : activeOffers.first.id;
        _loadingOffers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _offersError = e.toString();
        _loadingOffers = false;
      });
    }
  }

  OfferModel? get _selectedOffer {
    final selectedId = _selectedOfferId;
    if (selectedId == null) return null;
    for (final offer in _offers) {
      if (offer.id == selectedId) return offer;
    }
    return null;
  }

  bool get _canSubmit {
    return !_submitting &&
        _selectedOfferId != null &&
        _couponController.text.trim().isNotEmpty;
  }

  Future<void> _openScanner() async {
    final scannedRaw = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QrCouponScannerScreen(),
      ),
    );

    if (!mounted) return;

    if (scannedRaw == null || scannedRaw.trim().isEmpty) {
      return;
    }

    final parsed = QrPayloadParser.parse(scannedRaw);
    if (parsed.couponCode.isEmpty) {
      DialogHelper.showErrorSnackBar(context, 'Scanned QR has no coupon code');
      return;
    }

    String feedback = 'Coupon captured from QR';
    final payloadOfferId = parsed.offerId;
    if (payloadOfferId != null && payloadOfferId.isNotEmpty) {
      final hasOffer = _offers.any((offer) => offer.id == payloadOfferId);
      if (hasOffer) {
        _selectedOfferId = payloadOfferId;
        feedback = 'Coupon and offer captured from QR';
      }
    }

    setState(() {
      _couponController.text = parsed.couponCode.trim();
      _mode = RedemptionInputMode.qr;
      _lastError = null;
    });

    DialogHelper.showSuccessSnackBar(context, feedback);
  }

  Future<void> _verify() async {
    if (!_canSubmit) return;

    setState(() {
      _submitting = true;
      _lastError = null;
    });

    try {
      final code = _couponController.text.trim();
      final offerId = _selectedOfferId!;

      final result = _mode == RedemptionInputMode.qr
          ? await RedemptionService.instance.verify(
              couponCode: code,
              offerId: offerId,
            )
          : await RedemptionService.instance.manualVerify(
              couponCode: code,
              offerId: offerId,
            );

      if (!mounted) return;
      setState(() {
        _lastResponse = result;
        _submitting = false;
      });

      DialogHelper.showSuccessSnackBar(context, result.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastError = e.toString();
        _submitting = false;
      });
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _redeem() async {
    if (!_canSubmit) return;

    setState(() {
      _submitting = true;
      _lastError = null;
    });

    try {
      final result = await RedemptionService.instance.redeem(
        couponCode: _couponController.text.trim(),
        offerId: _selectedOfferId!,
        verificationMethod: _mode == RedemptionInputMode.qr ? 'qr' : 'manual',
      );

      if (!mounted) return;
      setState(() {
        _lastResponse = result;
        _submitting = false;
      });

      DialogHelper.showSuccessSnackBar(context, result.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastError = e.toString();
        _submitting = false;
      });
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Customer Coupon'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RedemptionHistoryScreen(
                    initialOfferId: _selectedOfferId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeHelper.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: DataStateWrapper(
            loading: _loadingOffers,
            error: _offersError,
            isEmpty: _offers.isEmpty,
            onRetry: _loadOffers,
            emptyTitle: 'No active offers found',
            emptyMessage:
                'Create at least one active offer before verifying coupons.',
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.spaceMD,
                AppTokens.spaceSM,
                AppTokens.spaceMD,
                AppTokens.space2XL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTokens.spaceMD),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppTokens.radiusLG),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offer Selection',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppTokens.spaceSM),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedOfferId,
                            isExpanded: true,
                            dropdownColor: AppColors.elevated,
                            items: _offers
                                .map(
                                  (offer) => DropdownMenuItem<String>(
                                    value: offer.id,
                                    child: Text(
                                      '${offer.title} • ${offer.id.substring(0, 8)}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedOfferId = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  Container(
                    padding: const EdgeInsets.all(AppTokens.spaceMD),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppTokens.radiusLG),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification Mode',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppTokens.spaceSM),
                        ToggleButtons(
                          isSelected: [
                            _mode == RedemptionInputMode.qr,
                            _mode == RedemptionInputMode.manual,
                          ],
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusMD),
                          constraints: const BoxConstraints(
                            minHeight: 44,
                            minWidth: 140,
                          ),
                          onPressed: (index) {
                            setState(() {
                              _mode = index == 0
                                  ? RedemptionInputMode.qr
                                  : RedemptionInputMode.manual;
                            });
                          },
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: AppTokens.spaceMD),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded, size: 18),
                                  SizedBox(width: AppTokens.spaceSM),
                                  Text('QR Verify'),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: AppTokens.spaceMD),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.keyboard_rounded, size: 18),
                                  SizedBox(width: AppTokens.spaceSM),
                                  Text('Manual Verify'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.spaceMD),
                        TextField(
                          controller: _couponController,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Coupon Code',
                            hintText: 'Enter or paste coupon code',
                            prefixIcon:
                                const Icon(Icons.confirmation_num_rounded),
                            suffixIcon: IconButton(
                              tooltip: 'Scan QR',
                              onPressed: _mode == RedemptionInputMode.qr
                                  ? _openScanner
                                  : null,
                              icon: Icon(
                                Icons.qr_code_scanner_rounded,
                                color: _mode == RedemptionInputMode.qr
                                    ? AppColors.accent
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                        if (_mode == RedemptionInputMode.qr) ...[
                          const SizedBox(height: AppTokens.spaceSM),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _openScanner,
                              icon: const Icon(Icons.camera_alt_rounded),
                              label: const Text('Open Camera Scanner'),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppTokens.spaceMD),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _canSubmit ? _verify : null,
                                icon: const Icon(Icons.verified_rounded),
                                label: const Text('Verify'),
                              ),
                            ),
                            const SizedBox(width: AppTokens.spaceSM),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _canSubmit ? _redeem : null,
                                icon: _submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.check_circle_rounded),
                                label: Text(
                                    _submitting ? 'Processing...' : 'Redeem'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  if (_selectedOffer != null)
                    Container(
                      padding: const EdgeInsets.all(AppTokens.spaceMD),
                      decoration: BoxDecoration(
                        color: AppColors.elevated,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMD),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Offer',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.textMuted,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spaceXS),
                          Text(
                            _selectedOffer!.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppTokens.spaceMD),
                  _ResultPanel(
                    response: _lastResponse,
                    error: _lastError,
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RedemptionHistoryScreen(
                            initialOfferId: _selectedOfferId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('Open Redemption History'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.response,
    required this.error,
  });

  final RedemptionResponse? response;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = error != null && error!.isNotEmpty;

    final Color accent = hasError
        ? AppColors.error
        : (response == null ? AppColors.textMuted : AppColors.success);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spaceMD),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTokens.radiusLG),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasError
                    ? Icons.error_outline_rounded
                    : response == null
                        ? Icons.info_outline_rounded
                        : Icons.check_circle_outline_rounded,
                color: accent,
              ),
              const SizedBox(width: AppTokens.spaceSM),
              Text(
                hasError
                    ? 'Last operation failed'
                    : response == null
                        ? 'Awaiting verification'
                        : 'Last operation successful',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceSM),
          if (hasError)
            Text(
              error!,
              style: theme.textTheme.bodyMedium,
            )
          else if (response == null)
            Text(
              'Verify a coupon first to preview details, then redeem it securely.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            Text(
              response!.message,
              style: theme.textTheme.bodyMedium,
            ),
            if (response!.verification != null) ...[
              const SizedBox(height: AppTokens.spaceSM),
              Text(
                'Coupon: ${response!.verification!.coupon.code}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppTokens.spaceXS),
              Text(
                'Offer: ${response!.verification!.offer.title}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (response!.redemption != null) ...[
              const SizedBox(height: AppTokens.spaceXS),
              Text(
                'Redeemed at: ${response!.redemption!.redeemedAt?.toLocal().toString() ?? '--'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
