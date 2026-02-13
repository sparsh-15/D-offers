import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/dialog_helper.dart';
import '../../models/role_enum.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';

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

  bool _isLoading = false;
  bool _isLoadingPincode = false;
  List<Map<String, dynamic>> _availableAreas = [];
  String? _selectedArea;

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

        // Auto-select first area if only one available
        if (areas.length == 1) {
          _selectedArea = areas[0]['name'];
          _cityController.text = areas[0]['name'] ?? '';
        } else if (areas.isEmpty) {
          // Fallback to district if no areas
          _cityController.text = result['district']?.toString() ?? '';
        } else {
          // Multiple areas - user needs to select
          _cityController.clear();
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
      _cityController.text = areaName;
    });
  }

  String _title() {
    switch (widget.role) {
      case UserRole.customer:
        return 'Customer Signup';
      case UserRole.shopkeeper:
        return 'Shopkeeper Signup';
      case UserRole.admin:
        return 'Admin Signup';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.backgroundGradient
              : AppColors.lightBackgroundGradient,
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
                  Text(
                    _title(),
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your details to signup',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Enter your name',
                    prefixIcon: Icons.person_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
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
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _pincodeController,
                    label: 'Pincode',
                    hint: '6-digit pincode',
                    prefixIcon: Icons.location_on_rounded,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter pincode';
                      }
                      if (value.length != 6) {
                        return 'Please enter valid 6-digit pincode';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _availableAreas.length > 1
                            ? DropdownButtonFormField<String>(
                                value: _selectedArea,
                                decoration: InputDecoration(
                                  labelText: 'City / Area',
                                  prefixIcon:
                                      const Icon(Icons.location_city_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                hint: const Text('Select your area'),
                                items: _availableAreas.map((area) {
                                  return DropdownMenuItem<String>(
                                    value: area['name'],
                                    child: Text(area['name'] ?? ''),
                                  );
                                }).toList(),
                                onChanged:
                                    _isLoadingPincode ? null : _onAreaSelected,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please select area';
                                  }
                                  return null;
                                },
                              )
                            : CustomTextField(
                                controller: _cityController,
                                label: 'City',
                                hint: _availableAreas.isEmpty
                                    ? 'Enter city'
                                    : 'Auto-filled',
                                prefixIcon: Icons.location_city_rounded,
                                enabled: !_isLoadingPincode,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'City required';
                                  }
                                  return null;
                                },
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _stateController,
                          label: 'State',
                          hint: 'Auto-filled',
                          prefixIcon: Icons.map_rounded,
                          enabled: !_isLoadingPincode,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'State required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_isLoadingPincode)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Looking up pincode...',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  if (_availableAreas.length > 1 && !_isLoadingPincode)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${_availableAreas.length} areas found. Please select your area.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _addressController,
                    label: 'Address (optional)',
                    hint: 'House / Street / Locality',
                    prefixIcon: Icons.home_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: AppStrings.sendOtp,
                    onPressed: _handleSignup,
                    isLoading: _isLoading,
                    icon: Icons.send_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signup(
        role: widget.role,
        phone: _phoneController.text,
        name: _nameController.text.trim(),
        pincode: _pincodeController.text,
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
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
