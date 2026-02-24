import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/role_enum.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/custom_button.dart';
import '../customer/customer_dashboard.dart';
import '../shopkeeper/shop_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../core/utils/dialog_helper.dart';
import 'login_screen.dart';
import '../../core/utils/theme_helper.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final UserRole? role;
  final bool isRegistration;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.role,
    this.isRegistration = false,
  }) : assert(!isRegistration || role != null,
            'role is required for registration flow');

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 30;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        _startResendTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeHelper.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Iconsax.arrow_left_2),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                FadeInDown(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.2),
                            AppColors.accent.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Iconsax.shield_tick,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    AppStrings.verifyOtp,
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                FadeInDown(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    '${AppStrings.otpSent} +91 ${widget.phoneNumber}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 60),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      6,
                      (index) => _buildOtpField(index),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: CustomButton(
                    text: AppStrings.verifyOtp,
                    onPressed: _handleVerifyOtp,
                    isLoading: _isLoading,
                    icon: Iconsax.tick_circle,
                  ),
                ),
                const SizedBox(height: 24),
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive OTP? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _resendTimer == 0 ? _handleResendOtp : null,
                        child: Text(
                          _resendTimer > 0
                              ? 'Resend in ${_resendTimer}s'
                              : AppStrings.resendOtp,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _resendTimer == 0
                                        ? AppColors.primary
                                        : AppColors.textHint,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _otpControllers[index].text.isNotEmpty
              ? AppColors.primary
              : (isDark ? AppColors.white24 : AppColors.black12),
          width: 2,
        ),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: ThemeHelper.getTextColor(context),
              fontWeight: FontWeight.bold,
            ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.verifyOtp(
        role: widget.role,
        phone: widget.phoneNumber,
        otp: otp,
      );
      if (!mounted) return;
      final user = AuthStore.currentUser;
      if (user == null) {
        DialogHelper.showErrorSnackBar(
            context, 'Login failed. Please try again.');
        return;
      }
      // If this is a registration flow, show success and redirect to login
      if (widget.isRegistration) {
        if (!mounted) return;
        DialogHelper.showSuccessSnackBar(
          context,
          'Registration successful!',
        );
        // Clear auth store since we're redirecting to login
        AuthStore.clear();
        // Navigate back to login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
          (route) => false,
        );
        return;
      }

      _navigateByRole();
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().toLowerCase();

      // Handle rate limit errors specifically
      if (errorMessage.contains('too many') ||
          errorMessage.contains('429') ||
          errorMessage.contains('rate limit')) {
        DialogHelper.showErrorSnackBar(
          context,
          'Too many verification attempts. Please wait 15 minutes before trying again.',
        );
      } else {
        // Remove "Exception: " prefix if present
        final cleanMessage = errorMessage.replaceFirst('exception: ', '');
        DialogHelper.showErrorSnackBar(context, cleanMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendTimer > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Please wait ${_resendTimer} seconds before resending')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resendTimer = 30;
    });
    _startResendTimer();

    try {
      await AuthService.instance.sendOtp(
        role: widget.role,
        phone: widget.phoneNumber,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().toLowerCase();

      // Handle rate limit errors specifically
      if (errorMessage.contains('too many') ||
          errorMessage.contains('429') ||
          errorMessage.contains('rate limit')) {
        DialogHelper.showErrorSnackBar(
          context,
          'Too many OTP requests. Please wait 15 minutes before trying again.',
        );
        setState(() => _resendTimer = 900); // Set to 15 minutes
      } else {
        DialogHelper.showErrorSnackBar(
          context,
          'Failed to resend OTP. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateByRole() {
    final user = AuthStore.currentUser;
    if (user == null) {
      DialogHelper.showErrorSnackBar(context, 'Unable to resolve user role');
      return;
    }

    Widget destination;
    switch (user.role) {
      case UserRole.customer:
        destination = const CustomerDashboard();
        break;
      case UserRole.shopkeeper:
        destination = const ShopDashboard();
        break;
      case UserRole.admin:
      case UserRole.companySalesAgent:
      case UserRole.ssa:
        destination = const AdminDashboard();
        break;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }
}
