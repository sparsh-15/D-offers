import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../widgets/pincode_location_section.dart';
import '../ssa/ssa_dashboard.dart';

class _SP {
  static const canvas        = Color(0xFFF3F5F8);
  static const surface       = Color(0xFFFFFFFF);
  static const heroBg        = Color(0xFFFBEDD8);
  static const heroBorder    = Color(0xFFF0D5B0);
  static const heroIconBg    = Color(0xFFF8E0BC);
  static const border        = Color(0xFFDDE4ED);
  static const fieldBg       = Color(0xFFF4F7FB);
  static const accent        = Color(0xFFE88428);
  static const textPrimary   = Color(0xFF102038);
  static const textSecondary = Color(0xFF334155);
  static const textMuted     = Color(0xFF5E6D82);
  static const iconColor     = Color(0xFF707889);
  static const success       = Color(0xFF1F9D65);
  static const successBg     = Color(0xFFE4F6EC);
  static const white         = Color(0xFFFFFFFF);
}

class BecomeSSAOnboardingScreen extends StatefulWidget {
  const BecomeSSAOnboardingScreen({super.key});
  @override
  State<BecomeSSAOnboardingScreen> createState() => _BecomeSSAOnboardingScreenState();
}

class _BecomeSSAOnboardingScreenState extends State<BecomeSSAOnboardingScreen> {
  final _formKey           = GlobalKey<FormState>();
  final _emailController   = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController    = TextEditingController();
  final _stateController   = TextEditingController();

  bool _isLoading        = false;
  bool _isLoadingPincode = false;
  bool _success          = false;
  List<Map<String, dynamic>> _availableAreas = [];
  String? _selectedArea;

  @override
  void initState() {
    super.initState();
    // ignore: unused_local_variable
    final user = AuthStore.currentUser;
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
        _selectedArea = areas.isNotEmpty ? areas[0]['name']?.toString() : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cityController.clear();
        _stateController.clear();
        _availableAreas = [];
        _selectedArea = null;
      });
    } finally {
      if (mounted) setState(() => _isLoadingPincode = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.becomeSSA(
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        pincode: _pincodeController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
      );
      if (!mounted) return;
      setState(() { _isLoading = false; _success = true; });
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
    DialogHelper.showSuccessSnackBar(context, 'You are now a Service Sales Agent. Welcome!');
  }

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: _SP.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 100, height: 100,
                margin: const EdgeInsets.only(bottom: 24),
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: _SP.successBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 52, color: _SP.success),
              ),
              Text(
                "You're now a Service Sales Agent!",
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: _SP.textPrimary, height: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                'Use your SSA dashboard to view assigned shopkeepers and stats.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 14, color: _SP.textMuted, height: 1.5),
              ),
              const SizedBox(height: 36),
              SizedBox(
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _goToSsaDashboard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _SP.accent, foregroundColor: _SP.white,
                    elevation: 0, shape: const StadiumBorder(),
                    textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.dashboard_rounded, size: 20),
                  label: const Text(AppStrings.goToSsaDashboard),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _buildSuccess();

    return Scaffold(
      backgroundColor: _SP.canvas,
      appBar: AppBar(
        backgroundColor: _SP.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: _SP.canvas,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF334155)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Sales Agent',
          style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: _SP.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero card
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  decoration: BoxDecoration(
                    color: _SP.heroBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _SP.heroBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46, height: 46,
                            decoration: const BoxDecoration(color: _SP.heroIconBg, shape: BoxShape.circle),
                            child: const Icon(Iconsax.people, color: _SP.accent, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Become a SSA',
                                    style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w800, color: _SP.textPrimary)),
                                const SizedBox(height: 2),
                                Text('Earn by managing coupons',
                                    style: GoogleFonts.dmSans(fontSize: 13, color: _SP.textMuted)),
                              ],
                            ),
                          ),
                          const Icon(Icons.auto_awesome_rounded, color: _SP.accent, size: 20),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Any customer can become a Service Sales Agent. Fill in the details below to get started.',
                        style: GoogleFonts.dmSans(fontSize: 13, color: _SP.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Form card
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  decoration: BoxDecoration(
                    color: _SP.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _SP.border, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Email Address'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500, color: _SP.textPrimary),
                        decoration: _dec(hint: 'Enter your email', icon: Iconsax.sms),
                        validator: (value) {
                          if ((value?.trim() ?? '').isEmpty) return 'Email is required for SSA onboarding';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
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
                        pincodeValidator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter pincode';
                          if (value.length != 6) return 'Enter valid 6-digit pincode';
                          return null;
                        },
                        cityValidator: (value) {
                          if (value == null || value.toString().trim().isEmpty) return 'City required (from pincode)';
                          return null;
                        },
                        stateValidator: (value) {
                          if (value == null || value.toString().trim().isEmpty) return 'State required (from pincode)';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // CTA button
                SizedBox(
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _SP.accent, foregroundColor: _SP.white,
                      disabledBackgroundColor: const Color(0xFFDDE4ED),
                      elevation: 0, shape: const StadiumBorder(),
                      textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    icon: _isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _SP.white))
                        : const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: Text(_isLoading ? 'Please wait...' : 'Continue as SSA'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: _SP.textMuted)),
  );

  InputDecoration _dec({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(fontSize: 15, color: _SP.textMuted),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 10, right: 8),
        child: Icon(icon, color: _SP.iconColor, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44),
      filled: true,
      fillColor: _SP.fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDE4ED))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _SP.accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE24D69), width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE24D69), width: 1.8)),
    );
  }
}
