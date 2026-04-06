import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/auth_store.dart';
import '../../services/loan_service.dart';
import '../../services/upload_service.dart';

class CustomerLoansTab extends StatefulWidget {
  const CustomerLoansTab({super.key});

  @override
  State<CustomerLoansTab> createState() => _CustomerLoansTabState();
}

class _CustomerLoansTabState extends State<CustomerLoansTab> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _panController = TextEditingController();
  final _salaryController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();

  String? _employmentType;
  String? _accountType;
  String? _bankStatementUrl;
  bool _cibilConsent = false;
  bool _communicationConsent = true;
  bool _isSubmitting = false;
  bool _isUploadingBankStatement = false;

  @override
  void initState() {
    super.initState();
    _prefillKnownUserDetails();
    _prefillFromLatestLoanApplication();
  }

  void _prefillKnownUserDetails() {
    final user = AuthStore.currentUser;
    if (user == null) return;

    final name = user.name.trim();
    if (_fullNameController.text.trim().isEmpty && name.isNotEmpty) {
      _fullNameController.text = name;
    }

    final digitsOnlyPhone = user.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigitPhone = digitsOnlyPhone.length > 10
        ? digitsOnlyPhone.substring(digitsOnlyPhone.length - 10)
        : digitsOnlyPhone;
    if (_mobileController.text.trim().isEmpty && tenDigitPhone.length == 10) {
      _mobileController.text = tenDigitPhone;
    }
  }

  Future<void> _prefillFromLatestLoanApplication() async {
    try {
      final applications =
          await LoanService.instance.getLoanApplications(limit: 1);
      if (!mounted || applications.isEmpty) return;

      final latest = applications.first;

      if (_employmentType == null &&
          _isValidEmploymentType(latest.employmentType)) {
        _employmentType = latest.employmentType;
      }
      if (_accountType == null && _isValidAccountType(latest.accountType)) {
        _accountType = latest.accountType;
      }
      if (_salaryController.text.trim().isEmpty &&
          latest.monthlySalaryIncome.trim().isNotEmpty) {
        _salaryController.text = latest.monthlySalaryIncome.trim();
      }
      if (_loanAmountController.text.trim().isEmpty &&
          latest.loanAmount.trim().isNotEmpty) {
        _loanAmountController.text = latest.loanAmount.trim();
      }
      if (_panController.text.trim().isEmpty &&
          latest.panNumber.trim().isNotEmpty) {
        _panController.text = latest.panNumber.trim().toUpperCase();
      }
      if (_bankNameController.text.trim().isEmpty &&
          latest.bankName.trim().isNotEmpty) {
        _bankNameController.text = latest.bankName.trim();
      }
      if (_accountNumberController.text.trim().isEmpty &&
          latest.last4AccountDigits.trim().length == 4) {
        _accountNumberController.text = latest.last4AccountDigits.trim();
      }

      setState(() {
        if (!_cibilConsent) {
          _cibilConsent = latest.cibilConsent;
        }
        if (!_communicationConsent) {
          _communicationConsent = latest.communicationConsent;
        }
      });
    } catch (_) {
      // Ignore prefill errors and keep form usable with manual input.
    }
  }

  bool _isValidEmploymentType(String value) {
    return const {
      'salaried',
      'self_employed',
      'business_owner',
      'freelancer',
    }.contains(value);
  }

  bool _isValidAccountType(String value) {
    return const {
      'salary',
      'savings',
      'current',
    }.contains(value);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _loanAmountController.dispose();
    _panController.dispose();
    _salaryController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_cibilConsent) {
      DialogHelper.showErrorSnackBar(
        context,
        'Please provide CIBIL consent before applying for a loan.',
      );
      return;
    }
    if (_bankStatementUrl == null || _bankStatementUrl!.isEmpty) {
      DialogHelper.showErrorSnackBar(
        context,
        'Please upload your last 3-month bank statement.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await LoanService.instance.submitLoanApplication(
        fullName: _fullNameController.text,
        mobileNumber: _mobileController.text,
        employmentType: _employmentType!,
        monthlySalaryIncome: _salaryController.text,
        loanAmount: _loanAmountController.text,
        panNumber: _panController.text,
        bankName: _bankNameController.text,
        accountType: _accountType!,
        last4AccountDigits: _accountNumberController.text,
        bankStatementUrl: _bankStatementUrl!,
        cibilConsent: _cibilConsent,
        communicationConsent: _communicationConsent,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response.success) {
        // Clear form on success
        _fullNameController.clear();
        _mobileController.clear();
        _loanAmountController.clear();
        _panController.clear();
        _salaryController.clear();
        _bankNameController.clear();
        _accountNumberController.clear();
        setState(() {
          _employmentType = null;
          _accountType = null;
          _bankStatementUrl = null;
          _cibilConsent = false;
          _communicationConsent = true;
        });
        _prefillKnownUserDetails();
        _prefillFromLatestLoanApplication();

        DialogHelper.showSuccessSnackBar(
          context,
          'Loan application submitted successfully. Application ID: ${response.loanApplicationId.substring(0, 8)}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _uploadBankStatement() async {
    if (_isUploadingBankStatement) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2000,
      maxHeight: 2000,
    );

    if (picked == null || !mounted) return;

    setState(() => _isUploadingBankStatement = true);
    try {
      final url = await UploadService.instance.uploadImage(File(picked.path));
      if (!mounted) return;
      setState(() {
        _bankStatementUrl = url;
        _isUploadingBankStatement = false;
      });
      DialogHelper.showSuccessSnackBar(
        context,
        'Bank statement uploaded successfully.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingBankStatement = false);
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6F8FB), Color(0xFFF1F4F8)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: false,
          titleSpacing: 16,
          title: Text(
            'Loan Application',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF1E2433),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LoanHeroCard(
                        onCheckEligibility: _submit,
                        isLoading: _isSubmitting,
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Personal Details',
                        subtitle: 'Use the mobile number registered in the app',
                        child: Column(
                          children: [
                            _ReadOnlyInfoField(
                              icon: Icons.person_outline_rounded,
                              value: _fullNameController.text.trim().isEmpty
                                  ? 'Abba'
                                  : _fullNameController.text.trim(),
                            ),
                            const SizedBox(height: 14),
                            _ReadOnlyInfoField(
                              icon: Icons.phone_outlined,
                              value: _mobileController.text.trim(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Income Details',
                        subtitle:
                            'Used for initial screening — fully confidential',
                        accentBorder: const Color(0xFFE6D8C8),
                        child: Column(
                          children: [
                            _LoanDropdownField(
                              value: _employmentType,
                              hint: 'Employment Type',
                              items: const [
                                DropdownMenuItem(
                                  value: 'salaried',
                                  child: Text('Salaried'),
                                ),
                                DropdownMenuItem(
                                  value: 'self_employed',
                                  child: Text('Self-employed'),
                                ),
                                DropdownMenuItem(
                                  value: 'business_owner',
                                  child: Text('Business owner'),
                                ),
                                DropdownMenuItem(
                                  value: 'freelancer',
                                  child: Text('Freelancer'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _employmentType = value),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select employment type';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _LoanFormField(
                              controller: _salaryController,
                              hint: 'Monthly income (₹)',
                              icon: Icons.attach_money_rounded,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter monthly income';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _LoanFormField(
                              controller: _loanAmountController,
                              hint: 'Loan amount required (₹)',
                              icon: Icons.attach_money_rounded,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter loan amount';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Verification Details',
                        subtitle:
                            'PAN, bank details and statement are required',
                        child: Column(
                          children: [
                            _LoanFormField(
                              controller: _panController,
                              hint: 'PAN number',
                              icon: Icons.badge_outlined,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9]')),
                              ],
                              validator: (value) {
                                final pan = (value ?? '').trim().toUpperCase();
                                if (pan.isEmpty) {
                                  return 'Please enter PAN number';
                                }
                                if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$')
                                    .hasMatch(pan)) {
                                  return 'Enter a valid PAN (e.g. ABCDE1234F)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _LoanFormField(
                              controller: _bankNameController,
                              hint: 'Bank name',
                              icon: Icons.account_balance_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter bank name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _LoanDropdownField(
                              value: _accountType,
                              hint: 'Account Type',
                              items: const [
                                DropdownMenuItem(
                                  value: 'salary',
                                  child: Text('Salary account'),
                                ),
                                DropdownMenuItem(
                                  value: 'savings',
                                  child: Text('Savings account'),
                                ),
                                DropdownMenuItem(
                                  value: 'current',
                                  child: Text('Current account'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _accountType = value),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select account type';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _LoanFormField(
                              controller: _accountNumberController,
                              hint: 'Last 4 digits of account number',
                              icon: Icons.attach_money_rounded,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter last 4 digits';
                                }
                                if (value.length != 4) {
                                  return 'Enter exactly 4 digits';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _UploadCard(
                              isUploading: _isUploadingBankStatement,
                              hasUploaded: _bankStatementUrl != null,
                              onPressed: _uploadBankStatement,
                            ),
                            const SizedBox(height: 14),
                            _ConsentCard(
                              cibilConsent: _cibilConsent,
                              communicationConsent: _communicationConsent,
                              onCibilChanged: (value) =>
                                  setState(() => _cibilConsent = value),
                              onCommunicationChanged: (value) =>
                                  setState(() => _communicationConsent = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE88428),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('Submit Application'),
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
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
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTokens.spaceXS),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _LoanInfoChip extends StatelessWidget {
  final String label;

  const _LoanInfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceSM,
        vertical: AppTokens.spaceXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(color: AppColors.borderMid),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _LoanHeroCard extends StatelessWidget {
  const _LoanHeroCard({
    required this.onCheckEligibility,
    required this.isLoading,
  });

  final VoidCallback onCheckEligibility;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF252B38),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 12,
            top: 16,
            child: Opacity(
              opacity: 0.2,
              child: Text(
                '₹',
                style: GoogleFonts.dmSans(
                  fontSize: 88,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Loan Assist',
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      'Check your eligibility in minutes and connect directly with our lending partners.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : onCheckEligibility,
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label:
                          Text(isLoading ? 'Checking...' : 'Check Eligibility'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE88428),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          textStyle: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.accentBorder,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Color? accentBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentBorder ?? const Color(0xFFDDE4ED),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF102038),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF5E6D82),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ReadOnlyInfoField extends StatelessWidget {
  const _ReadOnlyInfoField({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF707889), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF132033),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanFormField extends StatelessWidget {
  const _LoanFormField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(icon, color: const Color(0xFF707889)),
        filled: true,
        fillColor: const Color(0xFFF4F7FB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE88428), width: 1.2),
        ),
      ),
      style: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF132033),
      ),
    );
  }
}

class _LoanDropdownField extends StatelessWidget {
  const _LoanDropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    required this.validator,
  });

  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      menuMaxHeight: 280,
      validator: validator,
      onChanged: onChanged,
      items: items,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF4F7FB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE88428), width: 1.2),
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF707889)),
      dropdownColor: Colors.white,
      style: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF132033),
      ),
      hint: Text(
        hint,
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.isUploading,
    required this.hasUploaded,
    required this.onPressed,
  });

  final bool isUploading;
  final bool hasUploaded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasUploaded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6EC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF2E9E5B), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Bank statement uploaded',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B5E39),
                    ),
                  ),
                ],
              ),
            ),
          if (hasUploaded) const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: isUploading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF132033),
                side: const BorderSide(color: Color(0xFFD5DEE8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(hasUploaded
                      ? Icons.refresh_rounded
                      : Icons.upload_file_rounded),
              label: Text(isUploading
                  ? 'Uploading...'
                  : hasUploaded
                      ? 'Replace bank statement'
                      : 'Upload bank statement'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.cibilConsent,
    required this.communicationConsent,
    required this.onCibilChanged,
    required this.onCommunicationChanged,
  });

  final bool cibilConsent;
  final bool communicationConsent;
  final ValueChanged<bool> onCibilChanged;
  final ValueChanged<bool> onCommunicationChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: cibilConsent,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFFE88428),
            title: Text(
              'I consent to CIBIL and credit bureau verification.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF132033),
              ),
            ),
            subtitle: Text(
              'This allows the loan partner to check credit eligibility for my application.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                height: 1.35,
                color: const Color(0xFF64748B),
              ),
            ),
            onChanged: (value) => onCibilChanged(value ?? false),
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            value: communicationConsent,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFFE88428),
            title: Text(
              'I agree to receive calls, SMS, or WhatsApp updates about my application.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF132033),
              ),
            ),
            onChanged: (value) => onCommunicationChanged(value ?? false),
          ),
        ],
      ),
    );
  }
}
