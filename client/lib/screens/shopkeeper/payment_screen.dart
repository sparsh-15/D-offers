import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/auth_store.dart';
import '../../services/subscription_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.plan,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'upi';
  bool _isProcessing = false;
  final _upiIdController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _couponController = TextEditingController();

  Map<String, dynamic>? _quote;
  bool _quoteLoading = false;
  String? _quoteError;

  @override
  void initState() {
    super.initState();
    final signupCoupon = AuthStore.currentUser?.signupCouponCode;
    if (signupCoupon != null && signupCoupon.trim().isNotEmpty) {
      _couponController.text = signupCoupon.trim();
    }
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  int get _durationMonths {
    final durationDays = widget.plan['durationDays'] ?? 30;
    return (durationDays / 30).round().clamp(1, 24);
  }

  double get _basePrice {
    final monthlyPrice = (widget.plan['monthlyPrice'] ?? 0) is int
        ? (widget.plan['monthlyPrice'] as int).toDouble()
        : (widget.plan['monthlyPrice'] ?? 0).toDouble();
    return monthlyPrice * _durationMonths;
  }

  double get _displayPrice {
    if (_quote != null) {
      final fp = _quote!['finalPrice'];
      if (fp is num) return fp.toDouble();
    }
    return _basePrice;
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _quote = null;
        _quoteError = null;
      });
      return;
    }
    setState(() {
      _quoteLoading = true;
      _quoteError = null;
      _quote = null;
    });
    try {
      final planId = widget.plan['id']?.toString();
      final planType = widget.plan['name']?.toString();
      final quote = await SubscriptionService.instance.getQuote(
        planId: planId,
        planType: planType,
        durationMonths: _durationMonths,
        couponCode: code,
      );
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _quoteLoading = false;
        _quoteError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quote = null;
        _quoteLoading = false;
        _quoteError = e.toString();
      });
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeHelper.isDarkMode(context);
    final displayName = widget.plan['displayName'] ?? widget.plan['name'];
    final durationDays = widget.plan['durationDays'] ?? 30;

    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          leading: ThemeHelper.buildBackButton(context),
          title: const Text('Payment'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Plan Summary Card
              FadeInDown(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.accent.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Iconsax.ticket_discount,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$durationDays days subscription',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      if (_quote != null && (_quote!['discountAmount'] as num?) != null && (_quote!['discountAmount'] as num) > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              '₹${_basePrice.toStringAsFixed(0)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Discount',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                            Text(
                              '- ₹${(_quote!['discountAmount'] as num).toStringAsFixed(0)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '₹${_displayPrice.toStringAsFixed(0)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_quote != null && _quote!['attribution'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.ticket_discount, color: AppColors.success, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _quote!['attribution']['message']?.toString() ?? 'Referral discount applied',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Coupon code (optional)
              Text(
                'Have a coupon code?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        labelText: 'Coupon code (optional)',
                        prefixIcon: const Icon(Iconsax.ticket_discount),
                        errorText: _quoteError,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _applyCoupon(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _quoteLoading ? null : _applyCoupon,
                      child: _quoteLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Apply'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Payment Method Selection
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'Select Payment Method',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // UPI Option
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _buildPaymentMethodCard(
                  icon: Iconsax.wallet_3,
                  title: 'UPI',
                  subtitle: 'Pay using UPI ID',
                  value: 'upi',
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 12),

              // Card Option
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: _buildPaymentMethodCard(
                  icon: Iconsax.card,
                  title: 'Credit/Debit Card',
                  subtitle: 'Pay using card',
                  value: 'card',
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 12),

              // Net Banking Option
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: _buildPaymentMethodCard(
                  icon: Iconsax.bank,
                  title: 'Net Banking',
                  subtitle: 'Pay using internet banking',
                  value: 'netbanking',
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 32),

              // Payment Details Form
              if (_selectedPaymentMethod == 'upi')
                FadeIn(
                  child: _buildUPIForm(),
                ),
              if (_selectedPaymentMethod == 'card')
                FadeIn(
                  child: _buildCardForm(),
                ),
              if (_selectedPaymentMethod == 'netbanking')
                FadeIn(
                  child: _buildNetBankingForm(),
                ),
              const SizedBox(height: 32),

              // Pay Button
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.shield_tick),
                              const SizedBox(width: 12),
                              Text(
                                'Pay ₹${_displayPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Security Note
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.security,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your payment is secure and encrypted',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isDark,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : ThemeHelper.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.white24 : AppColors.black12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : (isDark
                        ? AppColors.white.withValues(alpha: 0.12)
                        : AppColors.black.withValues(alpha: 0.12)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : theme.iconTheme.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Iconsax.tick_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUPIForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter UPI Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _upiIdController,
          decoration: InputDecoration(
            labelText: 'UPI ID',
            hintText: 'example@upi',
            prefixIcon: const Icon(Iconsax.wallet_3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.info.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Iconsax.info_circle,
                color: AppColors.info,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Popular UPI apps: Google Pay, PhonePe, Paytm',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.info,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Card Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cardNumberController,
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            prefixIcon: const Icon(Iconsax.card),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          maxLength: 19,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cardHolderController,
          decoration: InputDecoration(
            labelText: 'Card Holder Name',
            hintText: 'John Doe',
            prefixIcon: const Icon(Iconsax.user),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiryController,
                decoration: InputDecoration(
                  labelText: 'Expiry',
                  hintText: 'MM/YY',
                  prefixIcon: const Icon(Iconsax.calendar),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.datetime,
                maxLength: 5,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _cvvController,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  prefixIcon: const Icon(Iconsax.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 3,
                obscureText: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetBankingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Bank',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Bank',
            prefixIcon: const Icon(Iconsax.bank),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'sbi', child: Text('State Bank of India')),
            DropdownMenuItem(value: 'hdfc', child: Text('HDFC Bank')),
            DropdownMenuItem(value: 'icici', child: Text('ICICI Bank')),
            DropdownMenuItem(value: 'axis', child: Text('Axis Bank')),
            DropdownMenuItem(
                value: 'kotak', child: Text('Kotak Mahindra Bank')),
            DropdownMenuItem(value: 'pnb', child: Text('Punjab National Bank')),
          ],
          onChanged: (value) {},
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.info.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Iconsax.info_circle,
                color: AppColors.info,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You will be redirected to your bank\'s website',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.info,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _processPayment() async {
    // Validate based on payment method
    if (_selectedPaymentMethod == 'upi') {
      if (_upiIdController.text.trim().isEmpty) {
        DialogHelper.showErrorSnackBar(context, 'Please enter UPI ID');
        return;
      }
    } else if (_selectedPaymentMethod == 'card') {
      if (_cardNumberController.text.trim().isEmpty ||
          _cardHolderController.text.trim().isEmpty ||
          _expiryController.text.trim().isEmpty ||
          _cvvController.text.trim().isEmpty) {
        DialogHelper.showErrorSnackBar(context, 'Please fill all card details');
        return;
      }
    }

    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final durationDays = widget.plan['durationDays'] ?? 30;
      final durationMonths = (durationDays / 30).round().clamp(1, 24);
      final planId = widget.plan['id']?.toString() ?? '';
      if (planId.isEmpty) {
        throw Exception('Invalid plan. Please log in again and retry.');
      }
      await SubscriptionService.instance.activateSubscription(
        planId: planId,
        durationMonths: durationMonths,
        paymentMethod: _selectedPaymentMethod,
        transactionId: 'dummy-${DateTime.now().millisecondsSinceEpoch}',
        couponCode: _couponController.text.trim().isEmpty
            ? null
            : _couponController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isProcessing = false);
      await _showPaymentSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      DialogHelper.showErrorSnackBar(
        context,
        'Payment captured, but subscription activation failed. Please log in again and try.',
      );
    }
  }

  Future<void> _showPaymentSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.tick_circle,
                color: AppColors.success,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Successful!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your subscription has been activated successfully.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close payment screen
                  widget.onPaymentSuccess(); // Callback
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
