import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/dialog_helper.dart';
import '../../models/role_enum.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pincode_location_section.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';
import '../../core/utils/theme_helper.dart';
import 'terms_screen.dart';

class RegisterScreen extends StatefulWidget {
  final UserRole role;

  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _addressController = TextEditingController();
  final _couponController = TextEditingController();
  final _occupationController = TextEditingController();
  final _aboutMeController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingPincode = false;
  List<Map<String, dynamic>> _availableAreas = [];
  String? _selectedArea;
  bool _acceptedTerms = true;
  String? _selectedGender;
  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();
    _pincodeController.addListener(_onPincodeChanged);
  }

  @override
  void dispose() {
    _pincodeController.removeListener(_onPincodeChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _couponController.dispose();
    _occupationController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  void _onPincodeChanged() {
    final pincode = _pincodeController.text;
    if (pincode.length == 6) {
      _lookupPincode(pincode);
    } else {
      setState(() {
        _cityController.clear();
        _stateController.clear();
        _availableAreas = [];
        _selectedArea = null;
      });
    }
  }

  Future<void> _lookupPincode(String pincode) async {
    setState(() => _isLoadingPincode = true);
    try {
      final result = await AuthService.instance.lookupPincode(pincode);
      if (!mounted) return;

      final areas = result['areas'] as List<Map<String, dynamic>>? ?? [];

      setState(() {
        _stateController.text = result['state']?.toString() ?? '';
        _availableAreas = areas;
        _cityController.text = result['district']?.toString() ?? '';

        if (areas.isNotEmpty) {
          _selectedArea = areas[0]['name']?.toString();
        } else {
          _selectedArea = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      // Silently fail - user can enter manually
      setState(() {
        _cityController.clear();
        _stateController.clear();
        _availableAreas = [];
        _selectedArea = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingPincode = false);
      }
    }
  }

  void _onAreaSelected(String? areaName) {
    if (areaName == null) return;
    setState(() {
      _selectedArea = areaName;
    });
  }

  String _title() {
    switch (widget.role) {
      case UserRole.customer:
        return 'Customer Signup';
      case UserRole.shopkeeper:
        return 'Shopkeeper Signup';
      case UserRole.companySalesAgent:
        return 'Sales Agent Signup';
      case UserRole.ssa:
      case UserRole.admin:
        return 'Restricted Signup';
    }
  }

  String _subtitle() {
    switch (widget.role) {
      case UserRole.customer:
        return 'start exploring local offers.';
      case UserRole.shopkeeper:
        return 'Start your onboarding in a few quick steps.';
      case UserRole.companySalesAgent:
        return 'Set up your agent account to continue.';
      case UserRole.ssa:
      case UserRole.admin:
        return 'Signup for this role is restricted.';
    }
  }

  IconData _roleIcon() {
    switch (widget.role) {
      case UserRole.customer:
        return Iconsax.profile_circle;
      case UserRole.shopkeeper:
        return Iconsax.shop;
      case UserRole.companySalesAgent:
        return Iconsax.ticket_discount;
      case UserRole.ssa:
        return Iconsax.security_user;
      case UserRole.admin:
        return Iconsax.shield_tick;
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 80, now.month, now.day);
    final lastDate = DateTime(now.year - 13, now.month, now.day);
    final initialDate = _selectedDob ?? lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isShopkeeper = widget.role == UserRole.shopkeeper;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeHelper.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceLG,
              vertical: AppTokens.spaceMD,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Iconsax.arrow_left_2),
                          onPressed: () => Navigator.pop(context),
                          color: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTokens.spaceSM),
                      Container(
                        padding: const EdgeInsets.all(AppTokens.spaceMD),
                        decoration: BoxDecoration(
                          color: AppColors.elevated,
                          borderRadius: BorderRadius.circular(AppTokens.radiusXL),
                          border: Border.all(color: AppColors.borderMid),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBackground,
                                    borderRadius: BorderRadius.circular(AppTokens.radiusMD),
                                    border: Border.all(color: AppColors.borderMid),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.asset(
                                    'assets/Dofferlogo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      _roleIcon(),
                                      color: AppColors.accent,
                                      size: AppTokens.iconXL,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppTokens.spaceMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.appName,
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _title(),
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _subtitle(),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppTokens.spaceSM),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.accent.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Icon(
                                    _roleIcon(),
                                    color: AppColors.accent,
                                    size: AppTokens.iconMD,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTokens.spaceSM),
                            Container(
                              height: 1,
                              color: AppColors.borderSubtle,
                            ),
                            const SizedBox(height: AppTokens.spaceSM),
                            Text(
                              'Secure OTP signup',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.spaceLG),
                      Container(
                        padding: const EdgeInsets.all(AppTokens.spaceLG),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(AppTokens.radiusXL),
                          border: Border.all(color: AppColors.borderMid),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FormSectionTitle(
                              title: 'Basic details',
                              subtitle: 'Use the same mobile number you will use for OTP login.',
                            ),
                            const SizedBox(height: AppTokens.spaceMD),
                            CustomTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              hint: 'Enter your name',
                              prefixIcon: Iconsax.user,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTokens.spaceMD),
                            CustomTextField(
                              controller: _phoneController,
                              label: AppStrings.enterMobile,
                              hint: AppStrings.mobileHint,
                              prefixIcon: Iconsax.mobile,
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
                            const SizedBox(height: AppTokens.spaceLG),
                            _FormSectionTitle(
                              title: 'Location details',
                              subtitle: isShopkeeper
                                  ? 'Add your owner location now. Detailed business address can be completed later.'
                                  : 'This helps us show relevant local offers and services.',
                            ),
                            const SizedBox(height: AppTokens.spaceMD),
                            PincodeLocationSection(
                              pincodeController: _pincodeController,
                              cityController: _cityController,
                              stateController: _stateController,
                              addressController: _addressController,
                              isLoadingPincode: _isLoadingPincode,
                              availableAreas: _availableAreas,
                              selectedArea: _selectedArea,
                              onAreaChanged: _onAreaSelected,
                              addressLabel: isShopkeeper
                                  ? 'Owner address (optional - detailed shop address can be added later)'
                                  : 'Address (optional)',
                              pincodeValidator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter pincode';
                                }
                                if (value.length != 6) {
                                  return 'Please enter valid 6-digit pincode';
                                }
                                return null;
                              },
                              cityValidator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'City required';
                                }
                                return null;
                              },
                              areaValidator: (value) {
                                if (_availableAreas.isNotEmpty &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'Please select area';
                                }
                                return null;
                              },
                              stateValidator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'State required';
                                }
                                return null;
                              },
                            ),
                            if (widget.role == UserRole.customer) ...[
                              const SizedBox(height: AppTokens.spaceLG),
                              const _FormSectionTitle(
                                title: 'Profile details',
                                subtitle: 'Optional details help personalize offers and conversations.',
                              ),
                              const SizedBox(height: AppTokens.spaceMD),
                              DropdownButtonFormField<String>(
                                value: _selectedGender,
                                decoration: const InputDecoration(
                                  labelText: 'Gender (optional)',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'male',
                                    child: Text('Male'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'female',
                                    child: Text('Female'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'other',
                                    child: Text('Other'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'prefer_not_to_say',
                                    child: Text('Prefer not to say'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedGender = value);
                                },
                              ),
                              const SizedBox(height: AppTokens.spaceMD),
                              InkWell(
                                onTap: _pickDob,
                                borderRadius: BorderRadius.circular(AppTokens.radiusMD),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date of birth (optional)',
                                    prefixIcon: Icon(Icons.cake_rounded),
                                  ),
                                  child: Text(
                                    _selectedDob == null
                                        ? 'Tap to select DOB'
                                        : '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: _selectedDob == null
                                          ? AppColors.textMuted
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTokens.spaceMD),
                              CustomTextField(
                                controller: _occupationController,
                                label: 'Occupation (optional)',
                                hint: 'e.g. Doctor, Student, Engineer',
                                prefixIcon: Icons.work_outline_rounded,
                                validator: (_) => null,
                              ),
                              const SizedBox(height: AppTokens.spaceMD),
                              CustomTextField(
                                controller: _aboutMeController,
                                label: 'About me (optional)',
                                hint: 'I work as a doctor',
                                prefixIcon: Icons.info_outline_rounded,
                                maxLines: 3,
                                validator: (_) => null,
                              ),
                            ],
                            if (widget.role == UserRole.shopkeeper) ...[
                              const SizedBox(height: AppTokens.spaceLG),
                              const _FormSectionTitle(
                                title: 'Referral details',
                                subtitle: 'Add a referral or coupon code if it applies to your onboarding.',
                              ),
                              const SizedBox(height: AppTokens.spaceMD),
                              CustomTextField(
                                controller: _couponController,
                                label: 'Referral / Coupon code (optional)',
                                hint: 'Enter code if you have one',
                                prefixIcon: Iconsax.ticket_discount,
                                validator: (_) => null,
                              ),
                              const SizedBox(height: AppTokens.spaceSM),
                              Text(
                                'You can change this later on the payment page.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppTokens.spaceLG),
                            Container(
                              padding: const EdgeInsets.all(AppTokens.spaceMD),
                              decoration: BoxDecoration(
                                color: AppColors.elevated,
                                borderRadius: BorderRadius.circular(AppTokens.radiusLG),
                                border: Border.all(color: AppColors.borderMid),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _acceptedTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _acceptedTerms = value ?? false;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: AppTokens.spaceSM),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text.rich(
                                          TextSpan(
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: AppColors.textPrimary,
                                              height: 1.45,
                                            ),
                                            children: [
                                              const TextSpan(text: 'I agree to the '),
                                              TextSpan(
                                                text: 'Terms & Conditions',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                             
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: AppTokens.spaceXS),
                                          ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTokens.spaceLG),
                            CustomButton(
                              text: AppStrings.sendOtp,
                              onPressed: _handleSignup,
                              isLoading: _isLoading,
                              icon: Iconsax.arrow_right_1,
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
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      DialogHelper.showErrorSnackBar(
        context,
        'Please accept the Terms & Conditions to continue.',
      );
      return;
    }
    if (widget.role == UserRole.admin) {
      DialogHelper.showErrorSnackBar(
        context,
        'Admin signup is restricted. Contact system administrator.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signup(
        role: widget.role,
        phone: _phoneController.text,
        name: _nameController.text.trim(),
        pincode: _pincodeController.text,
        acceptedTerms: _acceptedTerms,
        gender: widget.role == UserRole.customer ? _selectedGender : null,
        dob: widget.role == UserRole.customer && _selectedDob != null
            ? '${_selectedDob!.year.toString().padLeft(4, '0')}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}'
            : null,
        occupation: widget.role == UserRole.customer
            ? _occupationController.text.trim().isEmpty
                ? null
                : _occupationController.text.trim()
            : null,
        aboutMe: widget.role == UserRole.customer
            ? _aboutMeController.text.trim().isEmpty
                ? null
                : _aboutMeController.text.trim()
            : null,
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        couponCode: widget.role == UserRole.shopkeeper
            ? (_couponController.text.trim().isEmpty
                ? null
                : _couponController.text.trim())
            : null,
      );
      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(context, 'OTP sent for signup');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneNumber: _phoneController.text,
            role: widget.role,
            isRegistration: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _FormSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FormSectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppTokens.spaceXS),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
