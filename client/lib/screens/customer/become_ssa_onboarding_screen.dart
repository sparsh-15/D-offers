import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pincode_location_section.dart';
import '../ssa/ssa_dashboard.dart';

class BecomeSSAOnboardingScreen extends StatefulWidget {
  const BecomeSSAOnboardingScreen({super.key});

  @override
  State<BecomeSSAOnboardingScreen> createState() =>
      _BecomeSSAOnboardingScreenState();
}

class _BecomeSSAOnboardingScreenState extends State<BecomeSSAOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingPincode = false;
  bool _success = false;
  List<Map<String, dynamic>> _availableAreas = [];
  String? _selectedArea;

  @override
  void initState() {
    super.initState();
    final user = AuthStore.currentUser;
    if (user != null) {
      _emailController.text = ''; // User model doesn't expose email; leave empty for user to fill if needed
    }
    _pincodeController.addListener(_onPincodeChanged);
  }

  @override
  void dispose() {
    _pincodeController.removeListener(_onPincodeChanged);
    _emailController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.becomeSSA(
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        pincode: _pincodeController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _success = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  void _goToSsaDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SsaDashboard()),
      (route) => false,
    );
    DialogHelper.showSuccessSnackBar(
        context, 'You are now a Service Sales Agent. Welcome!');
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: ThemeHelper.getBackgroundGradient(context),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 80, color: AppColors.success),
                  const SizedBox(height: 24),
                  Text(
                    'You\'re now a Service Sales Agent',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use your SSA dashboard to view assigned shopkeepers and stats.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: AppStrings.goToSsaDashboard,
                    onPressed: _goToSsaDashboard,
                    icon: Icons.dashboard_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeHelper.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IconButton(
                    icon: const Icon(Iconsax.arrow_left_2),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.becomeSsaOnboardingTitle,
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.becomeSsaOnboardingDesc,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Email (required for SSA)',
                    prefixIcon: Iconsax.sms,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Email is required for SSA onboarding';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PincodeLocationSection(
                    pincodeController: _pincodeController,
                    cityController: _cityController,
                    stateController: _stateController,
                    addressController: null,
                    isLoadingPincode: _isLoadingPincode,
                    availableAreas: _availableAreas,
                    selectedArea: _selectedArea,
                    onAreaChanged: (v) => setState(() => _selectedArea = v),
                    showAddressField: false,
                    addressLabel: '',
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
                      if (value == null || value.toString().trim().isEmpty) {
                        return 'City required (from pincode)';
                      }
                      return null;
                    },
                    areaValidator: null,
                    stateValidator: (value) {
                      if (value == null || value.toString().trim().isEmpty) {
                        return 'State required (from pincode)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Continue as SSA',
                    onPressed: _submit,
                    isLoading: _isLoading,
                    icon: Iconsax.arrow_right_1,
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
