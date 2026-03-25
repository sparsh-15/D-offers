import 'package:flutter/material.dart';

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

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
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

      final value =
          (rewardRules['configValue'] as Map<String, dynamic>?) ?? const {};
      final amounts = (value['amounts'] as Map<String, dynamic>?) ?? const {};
      final limits = (value['limits'] as Map<String, dynamic>?) ?? const {};

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

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    final expiryDays = _readInt(_expiryDaysController.text);
    final likeOffer = _readInt(_likeOfferController.text);
    final purchaseSuccess = _readInt(_purchaseSuccessController.text);
    final saleClosed = _readInt(_saleClosedController.text);
    final installVerified = _readInt(_installVerifiedController.text);
    final likesPerDay = _readInt(_likesPerDayController.text);
    final customerDailyCoins = _readInt(_customerDailyCoinsController.text);
    final shopkeeperDailyCoins = _readInt(_shopkeeperDailyCoinsController.text);

    if ([
      expiryDays,
      likeOffer,
      purchaseSuccess,
      saleClosed,
      installVerified,
      likesPerDay,
      customerDailyCoins,
      shopkeeperDailyCoins,
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
        },
      );
      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(
          context, 'Reward config updated successfully');
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      DialogHelper.showErrorSnackBar(context, e.toString());
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
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 760;
                      return SingleChildScrollView(
                        padding: EdgeInsets.all(compact ? 12 : 16),
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
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _save,
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
                                    : 'Save Reward Rules'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: AppColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
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

  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
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
