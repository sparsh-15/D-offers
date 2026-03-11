import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'otp_screen.dart';
import '../role_selection/role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTokens.space3XL),

                // ── Logo ──────────────────────────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: Image.asset(
                      'assets/Dofferlogo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Iconsax.bag_2,
                        size: 40,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppTokens.spaceLG),

                // ── Headline ──────────────────────────────────────────────────
                
                Text(
                  'Welcome to ${AppStrings.appName}',
                  style: theme.textTheme.displayMedium,
                ),
                const SizedBox(height: AppTokens.spaceSM),
                Text(
                  AppStrings.loginToContinue,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppTokens.space2XL),

                // ── Phone input ───────────────────────────────────────────────
                CustomTextField(
                  controller: _phoneController,
                  label: AppStrings.enterMobile,
                  hint: AppStrings.mobileHint,
                  prefixIcon: Iconsax.mobile,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mobile number';
                    }
                    if (value.length != 10) {
                      return 'Enter a valid 10-digit number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTokens.spaceLG),

                // ── CTA ───────────────────────────────────────────────────────
                CustomButton(
                  text: AppStrings.sendOtp,
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                  icon: Iconsax.arrow_right_1,
                ),

                const SizedBox(height: AppTokens.spaceMD),

                // ── Register link ─────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New here?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoleSelectionScreen(),
                        ),
                      ),
                      child: Text(
                        'Register',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTokens.spaceLG),

                Text(
                  AppStrings.companyName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceXS),
                Text(
                  AppStrings.supportEmail,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.sendOtp(phone: _phoneController.text);
      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(context, 'OTP sent successfully');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneNumber: _phoneController.text,
            isRegistration: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final err = e.toString().toLowerCase();
      if (err.contains('too many') || err.contains('429')) {
        DialogHelper.showErrorSnackBar(
          context,
          'Too many attempts. Please wait 15 minutes.',
        );
      } else if (err.contains('not found') ||
          err.contains('account not found') ||
          err.contains('please signup')) {
        DialogHelper.showErrorSnackBar(
          context,
          'Account not found. Please register.',
        );
      } else {
        DialogHelper.showErrorSnackBar(
          context,
          err.replaceFirst('exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
