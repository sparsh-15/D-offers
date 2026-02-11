import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/role_enum.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;

  const LoginScreen({super.key, required this.role});

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

  String _getRoleTitle() {
    switch (widget.role) {
      case UserRole.customer:
        return 'Customer Login';
      case UserRole.shopkeeper:
        return 'Shopkeeper Login';
      case UserRole.admin:
        return 'Admin Login';
    }
  }

  IconData _getRoleIcon() {
    switch (widget.role) {
      case UserRole.customer:
        return Icons.shopping_bag_rounded;
      case UserRole.shopkeeper:
        return Icons.store_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInDown(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getRoleIcon(),
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      _getRoleTitle(),
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInDown(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      AppStrings.loginToContinue,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 60),
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: CustomTextField(
                      controller: _phoneController,
                      label: AppStrings.enterMobile,
                      hint: AppStrings.mobileHint,
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter mobile number';
                        }
                        if (value.length != 10) {
                          return 'Please enter valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: CustomButton(
                      text: AppStrings.sendOtp,
                      onPressed: _handleLogin,
                      isLoading: _isLoading,
                      icon: Icons.send_rounded,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.dontHaveAccount,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to register screen
                          },
                          child: Text(
                            AppStrings.register,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.primary,
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
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneNumber: _phoneController.text,
            role: widget.role,
          ),
        ),
      );
    }
  }
}
