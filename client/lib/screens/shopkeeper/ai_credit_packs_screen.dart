import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/subscription_service.dart';
import '../../widgets/data_state_wrapper.dart';

class AiCreditPacksScreen extends StatefulWidget {
  const AiCreditPacksScreen({super.key});

  @override
  State<AiCreditPacksScreen> createState() => _AiCreditPacksScreenState();
}

class _AiCreditPacksScreenState extends State<AiCreditPacksScreen> {
  List<Map<String, dynamic>> _packs = [];
  bool _loading = true;
  String? _error;
  String? _purchasingSku;

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    setState(() => _loading = true);
    try {
      final packs = await SubscriptionService.instance.getAiCreditPacksForShopkeeper();
      if (!mounted) return;
      setState(() {
        _packs = packs;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _purchasePack(Map<String, dynamic> pack) async {
    final sku = pack['sku'] as String? ?? '';
    setState(() => _purchasingSku = sku);
    try {
      await SubscriptionService.instance.purchaseAiCreditPack(
        packSku: sku,
        paymentMethod: 'upi',
        transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(context, 'Pack purchased successfully');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _purchasingSku = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: ThemeHelper.buildBackButton(context),
        title: const Text('AI Credit Packs'),
      ),
      body: DataStateWrapper(
        loading: _loading,
        error: _error,
        isEmpty: _packs.isEmpty,
        onRetry: _loadPacks,
        emptyTitle: 'No AI credit packs available',
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _packs.length,
          itemBuilder: (context, index) {
            final pack = _packs[index];
            return FadeInUp(
              delay: Duration(milliseconds: 80 * index),
              child: _buildPackCard(pack),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPackCard(Map<String, dynamic> pack) {
    final displayName = pack['displayName'] ?? pack['sku'] ?? 'Pack';
    final credits = pack['credits'] ?? 0;
    final price = pack['price'] ?? 0;
    final sku = pack['sku'] ?? '';
    final isPurchasing = _purchasingSku == sku;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text('$credits AI credits', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(
                  '₹$price',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPurchasing ? null : () => _purchasePack(pack),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.black,
                ),
                child: isPurchasing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Buy Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
