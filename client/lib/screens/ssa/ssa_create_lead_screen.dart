import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/ssa_service.dart';

class SsaCreateLeadScreen extends StatefulWidget {
  const SsaCreateLeadScreen({super.key});

  @override
  State<SsaCreateLeadScreen> createState() => _SsaCreateLeadScreenState();
}

class _SsaCreateLeadScreenState extends State<SsaCreateLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();

  bool _isSubmitting = false;
  List<Map<String, dynamic>> _coupons = const [];
  bool _loadingCoupons = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          title: const Text('New Lead'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.spaceMD),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create a new shop lead',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceXS),
                  Text(
                    'Capture basic shop details and optionally attach a coupon code.',
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
                      if (value == null || value.trim().isEmpty) {
                        return 'Shop name is required';
                      }
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
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone is required';
                      }
                      if (value.trim().length < 8) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pincodeController,
                          decoration: const InputDecoration(
                            labelText: 'Pincode',
                            prefixIcon: Icon(Icons.pin_drop_rounded),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppTokens.spaceSM),
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.location_city_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category (optional)',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
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
                                setState(() {
                                  _couponController.text = code;
                                });
                              },
                              itemBuilder: (context) {
                                return _coupons
                                    .map((c) => PopupMenuItem<String>(
                                          value: c['code']?.toString() ?? '',
                                          child: Text(
                                            c['code']?.toString() ?? '',
                                          ),
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
                      labelText: 'Notes (optional)',
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('Create Lead'),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await SsaService.instance.createLead(
        shopName: _shopNameController.text.trim(),
        phone: _phoneController.text.trim(),
        ownerName: _ownerNameController.text.trim().isEmpty
            ? null
            : _ownerNameController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty
            ? null
            : _pincodeController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        couponCode: _couponController.text.trim().isEmpty
            ? null
            : _couponController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop(true);
      DialogHelper.showSuccessSnackBar(
        context,
        'Lead created successfully',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      DialogHelper.showErrorSnackBar(
        context,
        e.toString(),
      );
    }
  }

  Future<void> _loadCoupons() async {
    setState(() => _loadingCoupons = true);
    try {
      final list = await SsaService.instance.getCoupons();
      if (!mounted) return;
      setState(() {
        _coupons = list;
        _loadingCoupons = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _coupons = const [];
        _loadingCoupons = false;
      });
    }
  }
}

