import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/dialog_helper.dart';
import '../../models/role_enum.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pincode_location_section.dart';
import '../../services/auth_service.dart';
import '../../services/upload_service.dart';
import 'otp_screen.dart';
import '../../core/utils/theme_helper.dart';

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
  final _shopRegistrationController = TextEditingController();
  final _gstController = TextEditingController();
  final _electricityBillController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _occupationController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final _workingHoursController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingPincode = false;
  bool _uploadingShopRegistrationDoc = false;
  bool _uploadingGstDoc = false;
  bool _uploadingElectricityDoc = false;
  bool _uploadingAadhaarDoc = false;
  bool _uploadingPanDoc = false;
  List<Map<String, dynamic>> _availableAreas = [];
  String? _selectedArea;
  bool _acceptedTerms = true;
  String? _selectedGender;
  DateTime? _selectedDob;
  String? _shopRegistrationDocumentUrl;
  String? _gstDocumentUrl;
  String? _electricityBillDocumentUrl;
  String? _aadhaarDocumentUrl;
  String? _panDocumentUrl;

  @override
  void initState() {
    super.initState();
    _pincodeController.addListener(_onPincodeChanged);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  Future<void> _pickAndUploadDocument(String kind) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
        withReadStream: true,
      );
      if (result == null || !mounted) return;
      
      final file = File(result.files.single.path ?? '');
      if (!file.existsSync()) {
        if (!mounted) return;
        DialogHelper.showErrorSnackBar(context, 'File not found');
        return;
      }
      
      await _uploadDocument(file, kind);
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, 'Failed to upload file: ${e.toString()}');
    }
  }

  Future<void> _uploadDocument(File file, String kind) async {
    setState(() {
      switch (kind) {
        case 'shopRegistration':
          _uploadingShopRegistrationDoc = true;
          break;
        case 'gst':
          _uploadingGstDoc = true;
          break;
        case 'electricity':
          _uploadingElectricityDoc = true;
          break;
        case 'aadhaar':
          _uploadingAadhaarDoc = true;
          break;
        case 'pan':
          _uploadingPanDoc = true;
          break;
      }
    });

    try {
      final url = await UploadService.instance.uploadDocument(file);
      if (!mounted) return;
      setState(() {
        switch (kind) {
          case 'shopRegistration':
            _shopRegistrationDocumentUrl = url;
            _uploadingShopRegistrationDoc = false;
            break;
          case 'gst':
            _gstDocumentUrl = url;
            _uploadingGstDoc = false;
            break;
          case 'electricity':
            _electricityBillDocumentUrl = url;
            _uploadingElectricityDoc = false;
            break;
          case 'aadhaar':
            _aadhaarDocumentUrl = url;
            _uploadingAadhaarDoc = false;
            break;
          case 'pan':
            _panDocumentUrl = url;
            _uploadingPanDoc = false;
            break;
        }
      });
      DialogHelper.showSuccessSnackBar(context, 'Document uploaded successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingShopRegistrationDoc = false;
        _uploadingGstDoc = false;
        _uploadingElectricityDoc = false;
        _uploadingAadhaarDoc = false;
        _uploadingPanDoc = false;
      });
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      final displayMsg = errorMsg.contains('Session expired') || errorMsg.contains('Not authenticated')
          ? 'Session expired. Please login again to upload documents.'
          : errorMsg;
      DialogHelper.showErrorSnackBar(context, displayMsg);
    }
  }

  void _openDocumentPreview(String? url, String title) {
    if (url == null || url.isEmpty) {
      DialogHelper.showErrorSnackBar(context, 'No uploaded document found.');
      return;
    }
    
    // Check if it's a PDF
    final isPdf = url.toLowerCase().endsWith('.pdf');
    
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              if (isPdf)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, size: 64, color: AppColors.accent),
                      const SizedBox(height: 16),
                      Text(
                        'PDF Document',
                        style: Theme.of(context).textTheme.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the link below to view the PDF',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // In a real app, you'd use url_launcher here
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('PDF URL: $url')),
                          );
                        },
                        child: const Text('Open PDF'),
                      ),
                    ],
                  ),
                )
              else
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Unable to preview this document.'),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
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
    _shopRegistrationController.dispose();
    _gstController.dispose();
    _electricityBillController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _occupationController.dispose();
    _aboutMeController.dispose();
    _workingHoursController.dispose();
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFFAB53D),
                                            Color(0xFFF8991D),
                                          ],
                                        ),
                                      ),
                                      child: const RotatedBox(
                                        quarterTurns: 1,
                                        child: Icon(
                                          Icons.local_offer_outlined,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      AppStrings.appName,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTokens.spaceSM),
                                Text(
                                  AppStrings.appName,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _title(),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _subtitle(),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.25,
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
                                        : _formatDate(_selectedDob!),
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
                                title: 'Business and KYC details',
                                subtitle:
                                    'Aadhaar and PAN required. Others optional.',
                              ),
                              const SizedBox(height: AppTokens.spaceMD),
                              _InputWithUpload(
                                label: 'Shop registration (optional)',
                                hint: 'Registration number',
                                controller: _shopRegistrationController,
                                prefixIcon: Iconsax.document_text,
                                isUploading: _uploadingShopRegistrationDoc,
                                hasUploadedFile: (_shopRegistrationDocumentUrl ?? '').isNotEmpty,
                                onUpload: () => _pickAndUploadDocument('shopRegistration'),
                                onView: () => _openDocumentPreview(
                                  _shopRegistrationDocumentUrl,
                                  'Shop Registration Document',
                                ),
                              ),
                              const SizedBox(height: AppTokens.spaceMD),
                              _InputWithUpload(
                                label: 'GST number (optional)',
                                hint: 'GST number',
                                controller: _gstController,
                                prefixIcon: Iconsax.receipt_2,
                                textCapitalization: TextCapitalization.characters,
                                isUploading: _uploadingGstDoc,
                                hasUploadedFile: (_gstDocumentUrl ?? '').isNotEmpty,
                                onUpload: () => _pickAndUploadDocument('gst'),
                                onView: () => _openDocumentPreview(
                                  _gstDocumentUrl,
                                  'GST Document',
                                ),
                              ),
                              const SizedBox(height: AppTokens.spaceMD),
                              _InputWithUpload(
                                label: 'Electricity bill (optional)',
                                hint: 'Consumer number',
                                controller: _electricityBillController,
                                prefixIcon: Iconsax.flash_1,
                                isUploading: _uploadingElectricityDoc,
                                hasUploadedFile: (_electricityBillDocumentUrl ?? '').isNotEmpty,
                                onUpload: () => _pickAndUploadDocument('electricity'),
                                onView: () => _openDocumentPreview(
                                  _electricityBillDocumentUrl,
                                  'Electricity Bill Document',
                                ),
                              ),
                              const SizedBox(height: AppTokens.spaceMD),
                              _InputWithUpload(
                                label: 'Aadhaar number',
                                hint: '12-digit',
                                controller: _aadhaarController,
                                prefixIcon: Iconsax.card,
                                keyboardType: TextInputType.number,
                                maxLength: 12,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (value) {
                                  final aadhaar = (value ?? '').trim();
                                  if (aadhaar.isEmpty) return 'Aadhaar required';
                                  if (!RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
                                    return 'Must be 12 digits';
                                  }
                                  return null;
                                },
                                isUploading: _uploadingAadhaarDoc,
                                hasUploadedFile: (_aadhaarDocumentUrl ?? '').isNotEmpty,
                                onUpload: () => _pickAndUploadDocument('aadhaar'),
                                onView: () => _openDocumentPreview(
                                  _aadhaarDocumentUrl,
                                  'Aadhaar Document',
                                ),
                              ),
                              const SizedBox(height: AppTokens.spaceMD),
                              _InputWithUpload(
                                label: 'PAN number',
                                hint: 'PAN',
                                controller: _panController,
                                prefixIcon: Iconsax.card_pos,
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 10,
                                validator: (value) {
                                  final pan = (value ?? '').trim().toUpperCase();
                                  if (pan.isEmpty) return 'PAN required';
                                  if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$')
                                      .hasMatch(pan)) {
                                    return 'Invalid PAN';
                                  }
                                  return null;
                                },
                                isUploading: _uploadingPanDoc,
                                hasUploadedFile: (_panDocumentUrl ?? '').isNotEmpty,
                                onUpload: () => _pickAndUploadDocument('pan'),
                                onView: () => _openDocumentPreview(
                                  _panDocumentUrl,
                                  'PAN Document',
                                ),
                              ),
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
                            if (widget.role == UserRole.companySalesAgent) ...[
                              const SizedBox(height: AppTokens.spaceLG),
                              const _FormSectionTitle(
                                title: 'Availability details',
                                subtitle: 'Share your preferred hours you can work.',
                              ),
                              const SizedBox(height: AppTokens.spaceMD),
                              CustomTextField(
                                controller: _workingHoursController,
                                label: 'Hours you can work',
                                hint: 'e.g. Monday-Saturday, 10 AM to 7 PM',
                                prefixIcon: Icons.schedule_rounded,
                                validator: (_) => null,
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
        shopRegistrationNumber: widget.role == UserRole.shopkeeper
          ? (_shopRegistrationController.text.trim().isEmpty
            ? null
            : _shopRegistrationController.text.trim())
          : null,
        gstNumber: widget.role == UserRole.shopkeeper
          ? (_gstController.text.trim().isEmpty
            ? null
            : _gstController.text.trim().toUpperCase())
          : null,
        electricityConsumerNumber: widget.role == UserRole.shopkeeper
          ? (_electricityBillController.text.trim().isEmpty
            ? null
            : _electricityBillController.text.trim())
          : null,
        aadhaarNumber: widget.role == UserRole.shopkeeper
          ? _aadhaarController.text.trim()
          : null,
        panNumber: widget.role == UserRole.shopkeeper
          ? _panController.text.trim().toUpperCase()
          : null,
        shopRegistrationDocumentUrl: widget.role == UserRole.shopkeeper
          ? _shopRegistrationDocumentUrl
          : null,
        gstDocumentUrl: widget.role == UserRole.shopkeeper
          ? _gstDocumentUrl
          : null,
        electricityBillDocumentUrl: widget.role == UserRole.shopkeeper
          ? _electricityBillDocumentUrl
          : null,
        aadhaarDocumentUrl: widget.role == UserRole.shopkeeper
          ? _aadhaarDocumentUrl
          : null,
        panDocumentUrl: widget.role == UserRole.shopkeeper
          ? _panDocumentUrl
          : null,
        workingHours: widget.role == UserRole.companySalesAgent
          ? (_workingHoursController.text.trim().isEmpty
            ? null
            : _workingHoursController.text.trim())
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
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      final displayMsg = errorMsg.contains('Session expired') || errorMsg.contains('Not authenticated')
          ? 'Session expired. Please login again.'
          : errorMsg;
      DialogHelper.showErrorSnackBar(context, displayMsg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _InputWithUpload extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final bool isUploading;
  final bool hasUploadedFile;
  final VoidCallback onUpload;
  final VoidCallback onView;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const _InputWithUpload({
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.validator,
    required this.isUploading,
    required this.hasUploadedFile,
    required this.onUpload,
    required this.onView,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomTextField(
                controller: controller,
                label: label,
                hint: hint,
                prefixIcon: prefixIcon,
                validator: validator,
                keyboardType: keyboardType,
                textCapitalization: textCapitalization,
                maxLength: maxLength,
                inputFormatters: inputFormatters,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: IconButton(
                onPressed: isUploading ? null : onUpload,
                icon: isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accent,
                          ),
                        ),
                      )
                    : const Icon(Icons.attach_file_rounded, size: 20),
                color: AppColors.accent,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        if (hasUploadedFile)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              spacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Uploaded',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'View document',
                ),
              ],
            ),
          ),
      ],
    );
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
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppTokens.spaceXS),
        Text(
          subtitle,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

