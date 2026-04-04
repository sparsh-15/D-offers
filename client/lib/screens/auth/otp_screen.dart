import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/role_enum.dart';
import '../../core/theme/revamp/login_revamp_theme.dart';
import '../customer/customer_dashboard.dart';
import '../shopkeeper/shop_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../company_sales_agent/csa_dashboard.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../core/utils/dialog_helper.dart';
import 'login_screen.dart';

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
  static const int _otpLength = 4;

  final List<TextEditingController> _otpControllers = List.generate(
    _otpLength,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (index) => FocusNode(),
  );
  bool _isLoading = false;
  int _resendTimer = 30;

  String get _maskedPhone {
    if (widget.phoneNumber.length < 4) return widget.phoneNumber;
    final visible = widget.phoneNumber.substring(widget.phoneNumber.length - 4);
    return '+91 ******$visible';
  }

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
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 430).clamp(0.84, 1.0);
    final sidePad = 24.0 * scale;

    return Scaffold(
      backgroundColor: LoginRevampColors.panel,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding:
                    EdgeInsets.fromLTRB(sidePad, 12 * scale, sidePad, 22 * scale),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: LoginRevampColors.textMuted,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                          ),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                          label: Text(
                            'Back',
                            style: LoginRevampTypography.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: LoginRevampColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 26 * scale),
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8EBCB),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x2EF8991D),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.verified_user_outlined,
                            size: 44,
                            color: LoginRevampColors.accent,
                          ),
                        ),
                      ),
                      SizedBox(height: 24 * scale),
                      Text(
                        'Verify OTP',
                        textAlign: TextAlign.center,
                        style: LoginRevampTypography.sectionTitle.copyWith(
                          fontSize: 40 * scale,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 10 * scale),
                      Text(
                        '4-digit code sent to',
                        textAlign: TextAlign.center,
                        style: LoginRevampTypography.sectionSubtitle.copyWith(
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        _maskedPhone,
                        textAlign: TextAlign.center,
                        style: LoginRevampTypography.body.copyWith(
                          fontSize: 32 * scale / 2,
                          color: LoginRevampColors.heading,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 30 * scale),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _otpLength,
                          (index) => _buildOtpField(index),
                        ),
                      ),
                      SizedBox(height: 32 * scale),
                      SizedBox(
                        height: 62,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LoginRevampColors.accent,
                            foregroundColor: LoginRevampColors.heading,
                            shape: const StadiumBorder(),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ).copyWith(
                            overlayColor:
                                WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Color(0xFF1E2335)),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.shield_outlined, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Verify',
                                      style: LoginRevampTypography.button.copyWith(
                                        fontSize: 18,
                                        color: LoginRevampColors.heading,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 18 * scale),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't get it? ",
                            style: LoginRevampTypography.sectionSubtitle.copyWith(
                              fontSize: 14,
                              color: LoginRevampColors.textMuted,
                            ),
                          ),
                          InkWell(
                            onTap: _resendTimer == 0 ? _handleResendOtp : null,
                            child: Text(
                              _resendTimer > 0
                                  ? 'Resend in ${_resendTimer}s'
                                  : 'Resend OTP',
                              style: LoginRevampTypography.body.copyWith(
                                fontSize: 14,
                                color: _resendTimer == 0
                                    ? LoginRevampColors.accent
                                    : LoginRevampColors.accent.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * scale),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    final hasValue = _otpControllers[index].text.isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;
    final borderColor = hasValue
        ? const Color(0xFF2FA772)
        : (isFocused ? LoginRevampColors.accent : const Color(0xFFD8D8D8));
    final valueColor = hasValue
      ? const Color(0xFF1F9E63)
      : (isFocused ? const Color(0xFF1A2340) : const Color(0xFF2B3147));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      width: 60,
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: isFocused ? 2.1 : 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isFocused ? const Color(0x2BF8991D) : const Color(0x17000000),
            blurRadius: isFocused ? 14 : 8,
            offset: const Offset(0, 3),
          ),
          const BoxShadow(
            color: Color(0x08FFFFFF),
            blurRadius: 1,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          cursorColor: LoginRevampColors.accent,
          cursorHeight: 20,
          cursorWidth: 1.6,
          style: LoginRevampTypography.sectionTitle.copyWith(
            fontSize: 31,
            color: valueColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          decoration: const InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            if (value.isNotEmpty && index < _otpLength - 1) {
              _focusNodes[index + 1].requestFocus();
            } else if (value.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != _otpLength) {
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

      final token = AuthStore.token;
      if (token != null) {
        await AuthStore.saveAuth(token, user);
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
      DialogHelper.showSuccessSnackBar(
        context,
        'OTP sent successfully',
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
        destination = const AdminDashboard();
        break;
      case UserRole.ssa:
        destination = const CustomerDashboard();
        break;
      case UserRole.companySalesAgent:
        destination = const CSADashboard();
        break;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }
}
