import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/reward_service.dart';

class RewardConfigScreen extends StatefulWidget {
  const RewardConfigScreen({super.key});

  @override
  State<RewardConfigScreen> createState() => _RewardConfigScreenState();
}

class _RewardConfigScreenState extends State<RewardConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _expiryDaysController = TextEditingController();
  final TextEditingController _likeOfferController = TextEditingController();
  final TextEditingController _purchaseSuccessController =
      TextEditingController();
  final TextEditingController _saleClosedController = TextEditingController();
  final TextEditingController _installVerifiedController =
      TextEditingController();
  final TextEditingController _likesPerDayController = TextEditingController();
  final TextEditingController _customerDailyCoinsController =
      TextEditingController();
  final TextEditingController _shopkeeperDailyCoinsController =
      TextEditingController();
  final TextEditingController _unlikeReversalWindowController =
      TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _unlikeReversalEnabled = true;
  int? _configVersion;
  bool _isDirty = false;
  String _initialSnapshot = '';

  static const _fieldBounds = <String, (int min, int max)>{
    'Like Offer': (1, 10000),
    'Purchase Success': (1, 10000),
    'Sale Closed': (1, 10000),
    'Install Verified': (1, 10000),
    'Expiry Days': (1, 365),
    'Likes Per Day': (1, 1000),
    'Customer Daily Coins': (1, 100000),
    'Shopkeeper Daily Coins': (1, 100000),
    'Unlike Reversal Window (minutes)': (1, 1440),
  };

  @override
  void initState() {
    super.initState();
    _attachDirtyListeners();
    _loadConfig();
  }

  @override
  void dispose() {
    _expiryDaysController.dispose();
    _likeOfferController.dispose();
    _purchaseSuccessController.dispose();
    _saleClosedController.dispose();
    _installVerifiedController.dispose();
    _likesPerDayController.dispose();
    _customerDailyCoinsController.dispose();
    _shopkeeperDailyCoinsController.dispose();
    _unlikeReversalWindowController.dispose();
    super.dispose();
  }

  void _attachDirtyListeners() {
    for (final controller in [
      _expiryDaysController,
      _likeOfferController,
      _purchaseSuccessController,
      _saleClosedController,
      _installVerifiedController,
      _likesPerDayController,
      _customerDailyCoinsController,
      _shopkeeperDailyCoinsController,
      _unlikeReversalWindowController,
    ]) {
      controller.addListener(_recalculateDirtyState);
    }
  }

  void _recalculateDirtyState() {
    if (_loading) return;
    final snapshot = _currentSnapshot();
    final dirtyNow = snapshot != _initialSnapshot;
    if (dirtyNow != _isDirty && mounted) {
      setState(() => _isDirty = dirtyNow);
    }
  }

  String _currentSnapshot() {
    return [
      _expiryDaysController.text.trim(),
      _likeOfferController.text.trim(),
      _purchaseSuccessController.text.trim(),
      _saleClosedController.text.trim(),
      _installVerifiedController.text.trim(),
      _likesPerDayController.text.trim(),
      _customerDailyCoinsController.text.trim(),
      _shopkeeperDailyCoinsController.text.trim(),
      _unlikeReversalWindowController.text.trim(),
      _unlikeReversalEnabled ? '1' : '0',
      '${_configVersion ?? ''}',
    ].join('|');
  }

  String? _validateBoundedInt(String label, String value,
      {bool enabled = true}) {
    if (!enabled) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '$label is required';
    final parsed = int.tryParse(trimmed);
    if (parsed == null) return '$label must be a valid number';
    final bounds = _fieldBounds[label];
    if (bounds == null) return null;
    if (parsed < bounds.$1 || parsed > bounds.$2) {
      return '$label must be between ${bounds.$1} and ${bounds.$2}';
    }
    return null;
  }

  Future<void> _loadConfig() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final configs = await RewardService.instance.listRewardConfigs();
      final rewardRules = configs.firstWhere(
        (c) => c['key'] == 'reward_rules',
        orElse: () => const <String, dynamic>{},
      );

      _configVersion = (rewardRules['version'] is num)
          ? (rewardRules['version'] as num).toInt()
          : int.tryParse('${rewardRules['version'] ?? ''}');

      final value =
          (rewardRules['configValue'] as Map<String, dynamic>?) ?? const {};
      final amounts = (value['amounts'] as Map<String, dynamic>?) ?? const {};
      final limits = (value['limits'] as Map<String, dynamic>?) ?? const {};
      final unlikeReversal =
          (value['unlikeReversal'] as Map<String, dynamic>?) ?? const {};

      _expiryDaysController.text =
          _toIntString(value['expiryDays'], fallback: 90);
      _likeOfferController.text =
          _toIntString(amounts['like_offer'], fallback: 50);
      _purchaseSuccessController.text =
          _toIntString(amounts['purchase_success'], fallback: 50);
      _saleClosedController.text =
          _toIntString(amounts['sale_closed'], fallback: 50);
      _installVerifiedController.text =
          _toIntString(amounts['install_verified'], fallback: 100);
      _likesPerDayController.text =
          _toIntString(limits['likesPerDay'], fallback: 20);
      _customerDailyCoinsController.text =
          _toIntString(limits['customerDailyCoins'], fallback: 300);
      _shopkeeperDailyCoinsController.text =
          _toIntString(limits['shopkeeperDailyCoins'], fallback: 1000);
      _unlikeReversalWindowController.text =
          _toIntString(unlikeReversal['windowMinutes'], fallback: 30);
      _unlikeReversalEnabled = unlikeReversal['enabled'] != false;

      if (!mounted) return;
      setState(() {
        _loading = false;
        _initialSnapshot = _currentSnapshot();
        _isDirty = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      DialogHelper.showErrorSnackBar(
          context, 'Please fix validation errors before saving.');
      return;
    }
    if (!_isDirty) {
      DialogHelper.showErrorSnackBar(context, 'No changes to save.');
      return;
    }

    final expiryDays = _readInt(_expiryDaysController.text);
    final likeOffer = _readInt(_likeOfferController.text);
    final purchaseSuccess = _readInt(_purchaseSuccessController.text);
    final saleClosed = _readInt(_saleClosedController.text);
    final installVerified = _readInt(_installVerifiedController.text);
    final likesPerDay = _readInt(_likesPerDayController.text);
    final customerDailyCoins = _readInt(_customerDailyCoinsController.text);
    final shopkeeperDailyCoins = _readInt(_shopkeeperDailyCoinsController.text);
    final unlikeReversalWindowMinutes =
        _readInt(_unlikeReversalWindowController.text);

    if ([
      expiryDays,
      likeOffer,
      purchaseSuccess,
      saleClosed,
      installVerified,
      likesPerDay,
      customerDailyCoins,
      shopkeeperDailyCoins,
      if (_unlikeReversalEnabled) unlikeReversalWindowMinutes,
    ].contains(null)) {
      DialogHelper.showErrorSnackBar(
          context, 'Please enter valid numeric values.');
      return;
    }

    setState(() => _saving = true);
    try {
      await RewardService.instance.updateRewardConfig(
        key: 'reward_rules',
        value: {
          'expiryDays': expiryDays,
          'amounts': {
            'like_offer': likeOffer,
            'purchase_success': purchaseSuccess,
            'sale_closed': saleClosed,
            'install_verified': installVerified,
          },
          'limits': {
            'likesPerDay': likesPerDay,
            'customerDailyCoins': customerDailyCoins,
            'shopkeeperDailyCoins': shopkeeperDailyCoins,
          },
          'unlikeReversal': {
            'enabled': _unlikeReversalEnabled,
            'windowMinutes': unlikeReversalWindowMinutes,
          },
        },
        version: _configVersion,
      );
      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(
          context, 'Reward config updated successfully');
      await _loadConfig();
      if (!mounted) return;
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.contains('CONFIG_VERSION_CONFLICT') ||
          message.toLowerCase().contains('version mismatch')) {
        DialogHelper.showErrorSnackBar(
          context,
          'Configuration was updated elsewhere. Reloading latest values.',
        );
        await _loadConfig();
      } else {
        DialogHelper.showErrorSnackBar(context, message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: ThemeHelper.buildBackButton(context),
        title: const Text('Reward Configuration'),
      ),
      body: Container(
        decoration:
            BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _loadConfig,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 760;
                      return SingleChildScrollView(
                        padding: EdgeInsets.all(compact ? 12 : 16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Reward Amounts (Coins)'),
                              const SizedBox(height: 8),
                              _buildResponsiveFields(
                                compact,
                                [
                                  _buildNumberField(
                                      'Like Offer', _likeOfferController),
                                  _buildNumberField('Purchase Success',
                                      _purchaseSuccessController),
                                  _buildNumberField(
                                      'Sale Closed', _saleClosedController),
                                  _buildNumberField('Install Verified',
                                      _installVerifiedController),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildSectionTitle('Limits'),
                              const SizedBox(height: 8),
                              _buildResponsiveFields(
                                compact,
                                [
                                  _buildNumberField(
                                      'Expiry Days', _expiryDaysController),
                                  _buildNumberField(
                                      'Likes Per Day', _likesPerDayController),
                                  _buildNumberField('Customer Daily Coins',
                                      _customerDailyCoinsController),
                                  _buildNumberField('Shopkeeper Daily Coins',
                                      _shopkeeperDailyCoinsController),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildSectionTitle('Unlike Reversal Policy'),
                              const SizedBox(height: 8),
                              SwitchListTile.adaptive(
                                value: _unlikeReversalEnabled,
                                onChanged: _saving
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _unlikeReversalEnabled = value;
                                        });
                                        _recalculateDirtyState();
                                      },
                                title: const Text('Enable Unlike Reversal'),
                                subtitle: const Text(
                                  'When disabled, unlike will not debit previously credited coins.',
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 8),
                              _buildResponsiveFields(
                                compact,
                                [
                                  _buildNumberField(
                                    'Unlike Reversal Window (minutes)',
                                    _unlikeReversalWindowController,
                                    enabled: _unlikeReversalEnabled,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      (_saving || !_isDirty) ? null : _save,
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.save_rounded),
                                  label: Text(_saving
                                      ? 'Saving...'
                                      : (_isDirty
                                          ? 'Save Reward Rules'
                                          : 'No Changes')),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: AppColors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleLarge,
    );
  }

  Widget _buildResponsiveFields(bool compact, List<Widget> children) {
    if (compact) {
      return Column(
        children: [
          for (final child in children)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: child,
            ),
        ],
      );
    }

    return GridView.builder(
      itemCount: children.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 3.2,
      ),
      itemBuilder: (_, index) => children[index],
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
  }) {
    final bounds = _fieldBounds[label];
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) => _validateBoundedInt(
        label,
        value ?? '',
        enabled: enabled,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        helperText:
            bounds == null ? null : 'Allowed range: ${bounds.$1}-${bounds.$2}',
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  int? _readInt(String value) {
    return int.tryParse(value.trim());
  }

  String _toIntString(dynamic value, {required int fallback}) {
    final numValue =
        value is num ? value.toInt() : int.tryParse('${value ?? ''}');
    return (numValue ?? fallback).toString();
  }
}
