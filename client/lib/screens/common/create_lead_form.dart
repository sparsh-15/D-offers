import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/auth_service.dart';
import '../../widgets/pincode_location_section.dart';

typedef CreateLeadCallback = Future<Map<String, dynamic>> Function({
  required String shopName,
  required String phone,
  String? ownerName,
  String? pincode,
  String? city,
  String? category,
  String? notes,
  String? couponCode,
});

/// Shared lead form for SSA and CSA: shop details + optional coupon.
class CreateLeadForm extends StatefulWidget {
  final String title;
  final String subtitle;
  final String submitButtonLabel;
  final Future<List<Map<String, dynamic>>> Function() loadCoupons;
  final CreateLeadCallback createLead;

  const CreateLeadForm({
    super.key,
    required this.title,
    required this.subtitle,
    required this.submitButtonLabel,
    required this.loadCoupons,
    required this.createLead,
  });

  @override
  State<CreateLeadForm> createState() => _CreateLeadFormState();
}

class _CreateLeadFormState extends State<CreateLeadForm> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();
  final _stateController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  List<Map<String, dynamic>> _coupons = const [];
  bool _loadingCoupons = true;
  bool _isLoadingPincode = false;
  List<Map<String, dynamic>> _availableAreas = [];
  String? _selectedArea;
  bool _isLoadingCategories = true;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    widget.loadCoupons().then((list) {
      if (mounted) setState(() { _coupons = list; _loadingCoupons = false; });
    }).catchError((_) {
      if (mounted) setState(() { _coupons = const []; _loadingCoupons = false; });
    });
    _pincodeController.addListener(_onPincodeChanged);
    _loadCategories();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _pincodeController.removeListener(_onPincodeChanged);
    super.dispose();
  }

  void _onPincodeChanged() {
    final pincode = _pincodeController.text;
    if (pincode.length == 6) {
      _lookupPincode(pincode);
    } else {
      setState(() {
        _availableAreas = [];
        _selectedArea = null;
        _isLoadingPincode = false;
      });
      _cityController.clear();
      _stateController.clear();
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
        _selectedArea = areas.isNotEmpty ? areas[0]['name']?.toString() : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _availableAreas = []; _selectedArea = null; });
    } finally {
      if (mounted) setState(() => _isLoadingPincode = false);
    }
  }

  void _onAreaSelected(String? areaName) {
    if (areaName == null) return;
    setState(() => _selectedArea = areaName);
  }

  Future<void> _loadCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _categories = [
        {'value': 'retail', 'label': 'Retail Store'},
        {'value': 'restaurant', 'label': 'Restaurant'},
        {'value': 'grocery', 'label': 'Grocery Store'},
        {'value': 'pharmacy', 'label': 'Pharmacy'},
        {'value': 'electronics', 'label': 'Electronics'},
        {'value': 'clothing', 'label': 'Clothing & Fashion'},
        {'value': 'beauty_salon', 'label': 'Beauty Salon & Spa'},
        {'value': 'gym_fitness', 'label': 'Gym & Fitness'},
        {'value': 'education', 'label': 'Education & Training'},
        {'value': 'healthcare', 'label': 'Healthcare'},
        {'value': 'automotive', 'label': 'Automotive'},
        {'value': 'home_services', 'label': 'Home Services'},
        {'value': 'entertainment', 'label': 'Entertainment'},
        {'value': 'food_beverage', 'label': 'Food & Beverage'},
        {'value': 'jewelry', 'label': 'Jewelry'},
        {'value': 'books_stationery', 'label': 'Books & Stationery'},
        {'value': 'sports', 'label': 'Sports & Outdoors'},
        {'value': 'pet_care', 'label': 'Pet Care'},
        {'value': 'travel', 'label': 'Travel & Tourism'},
        {'value': 'other', 'label': 'Other'},
      ];
      _isLoadingCategories = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final address = _addressController.text.trim();
      final rawNotes = _notesController.text.trim();
      String? combinedNotes;
      if (address.isNotEmpty && rawNotes.isNotEmpty) {
        combinedNotes = 'Address: $address\nNotes: $rawNotes';
      } else if (address.isNotEmpty) {
        combinedNotes = 'Address: $address';
      } else if (rawNotes.isNotEmpty) {
        combinedNotes = rawNotes;
      } else {
        combinedNotes = null;
      }

      final lead = await widget.createLead(
        shopName: _shopNameController.text.trim(),
        phone: _phoneController.text.trim(),
        ownerName: _ownerNameController.text.trim().isEmpty ? null : _ownerNameController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        notes: combinedNotes,
        couponCode: _couponController.text.trim().isEmpty ? null : _couponController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop(true);
      final resultType = lead['resultType']?.toString();
      final inviteStatus = lead['inviteStatus']?.toString() ?? 'pending';
      if (inviteStatus == 'failed') {
        DialogHelper.showErrorSnackBar(
          context,
          'Lead created, but invite OTP failed. You can retry from leads list.',
        );
      } else if (resultType == 'lead_created_existing_user_linked') {
        DialogHelper.showSuccessSnackBar(
          context,
          'Lead linked to existing shopkeeper and invite OTP sent.',
        );
      } else {
        DialogHelper.showSuccessSnackBar(
          context,
          'Lead created and invite OTP sent.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spaceMD),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.spaceXS),
            Text(
              widget.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),
            TextFormField(
              controller: _shopNameController,
              decoration: const InputDecoration(
                labelText: 'Shop name',
                prefixIcon: Icon(Icons.store_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Shop name is required';
                return null;
              },
            ),
            const SizedBox(height: AppTokens.spaceMD),
            TextFormField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                labelText: 'Owner name (optional)',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: AppTokens.spaceMD),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Owner mobile',
                prefixIcon: Icon(Icons.phone_rounded),
                counterText: '',
              ),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'Phone is required';
                if (v.length != 10) {
                  return 'Please enter valid 10-digit mobile number';
                }
                return null;
              },
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
              addressLabel:
                  'Owner address (optional – detailed shop address can be added later)',
              pincodeValidator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'Please enter pincode';
                if (v.length != 6) return 'Please enter valid 6-digit pincode';
                return null;
              },
              cityValidator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'City required';
                return null;
              },
              areaValidator: (value) {
                if (_availableAreas.isNotEmpty) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Please select area';
                }
                return null;
              },
              stateValidator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'State required';
                return null;
              },
            ),
            const SizedBox(height: AppTokens.spaceMD),
            _isLoadingCategories
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppTokens.spaceSM),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Business category (optional)',
                      hintText: 'Select business type',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    isExpanded: true,
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['value']?.toString(),
                        child: Text(category['label']?.toString() ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _categoryController.text = value ?? '';
                      });
                    },
                  ),
            const SizedBox(height: AppTokens.spaceMD),
            TextFormField(
              controller: _couponController,
              decoration: InputDecoration(
                labelText: 'Coupon code (optional)',
                prefixIcon: const Icon(Icons.local_offer_rounded),
                suffixIcon: _loadingCoupons || _coupons.isEmpty
                    ? null
                    : PopupMenuButton<String>(
                        icon: const Icon(Icons.expand_more_rounded),
                        onSelected: (code) {
                          setState(() => _couponController.text = code);
                        },
                        itemBuilder: (context) {
                          return _coupons
                              .map((c) => PopupMenuItem<String>(
                                    value: c['code']?.toString() ?? '',
                                    child: Text(c['code']?.toString() ?? ''),
                                  ))
                              .toList();
                        },
                      ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: AppTokens.spaceMD),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Business description / notes (optional)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppTokens.spaceLG),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : Text(widget.submitButtonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
