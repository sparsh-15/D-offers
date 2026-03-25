import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/theme_helper.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
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
      final applications = await LoanService.instance.getLoanApplications(limit: 1);
      if (!mounted || applications.isEmpty) return;

      final latest = applications.first;

      if (_employmentType == null && _isValidEmploymentType(latest.employmentType)) {
        _employmentType = latest.employmentType;
      }
      if (_accountType == null && _isValidAccountType(latest.accountType)) {
        _accountType = latest.accountType;
      }
      if (_salaryController.text.trim().isEmpty && latest.monthlySalaryIncome.trim().isNotEmpty) {
        _salaryController.text = latest.monthlySalaryIncome.trim();
      }
      if (_loanAmountController.text.trim().isEmpty && latest.loanAmount.trim().isNotEmpty) {
        _loanAmountController.text = latest.loanAmount.trim();
      }
      if (_panController.text.trim().isEmpty && latest.panNumber.trim().isNotEmpty) {
        _panController.text = latest.panNumber.trim().toUpperCase();
      }
      if (_bankNameController.text.trim().isEmpty && latest.bankName.trim().isNotEmpty) {
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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTokens.spaceLG),
                      decoration: BoxDecoration(
                        color: AppColors.elevated,
                        borderRadius: BorderRadius.circular(AppTokens.radiusXL),
                        border: Border.all(color: AppColors.borderMid),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppTokens.radiusMD),
                                ),
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceMD),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Loan Application',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: AppTokens.spaceXS),
                                    Text(
                                      'Share a few details to check eligibility and connect with the loan team.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                          _SectionHeader(
                            title: 'Personal details',
                            subtitle: 'Use the same mobile number you use in the app.',
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          CustomTextField(
                            controller: _fullNameController,
                            label: 'Full name',
                            hint: 'Enter your full name',
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          CustomTextField(
                            controller: _mobileController,
                            label: 'Mobile number',
                            hint: '10-digit mobile number',
                            prefixIcon: Icons.phone_rounded,
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
                          _SectionHeader(
                            title: 'Income details',
                            subtitle: 'These details are used for initial loan screening.',
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _employmentType,
                            decoration: const InputDecoration(
                              labelText: 'Employment type',
                              prefixIcon: Icon(Icons.work_outline_rounded),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'salaried', child: Text('Salaried')),
                              DropdownMenuItem(value: 'self_employed', child: Text('Self-employed')),
                              DropdownMenuItem(value: 'business_owner', child: Text('Business owner')),
                              DropdownMenuItem(value: 'freelancer', child: Text('Freelancer')),
                            ],
                            onChanged: (value) => setState(() => _employmentType = value),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select employment type';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          CustomTextField(
                            controller: _salaryController,
                            label: 'Monthly salary / income',
                            hint: 'Enter monthly income',
                            prefixIcon: Icons.currency_rupee_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter monthly income';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          CustomTextField(
                            controller: _loanAmountController,
                            label: 'Loan amount required',
                            hint: 'Enter desired loan amount',
                            prefixIcon: Icons.currency_rupee_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter loan amount';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTokens.spaceLG),
                          _SectionHeader(
                            title: 'Identification',
                            subtitle: 'PAN is required for credit check and KYC verification.',
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          CustomTextField(
                            controller: _panController,
                            label: 'PAN number',
                            hint: 'Example: ABCDE1234F',
                            prefixIcon: Icons.badge_outlined,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                            ],
                            validator: (value) {
                              final pan = (value ?? '').trim().toUpperCase();
                              if (pan.isEmpty) {
                                return 'Please enter PAN number';
                              }
                              if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan)) {
                                return 'Enter a valid PAN (e.g. ABCDE1234F)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTokens.spaceLG),
                          _SectionHeader(
                            title: 'Bank details',
                            subtitle: 'Keep this short. Only the basic banking details are required now.',
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          CustomTextField(
                            controller: _bankNameController,
                            label: 'Bank name',
                            hint: 'Enter your bank name',
                            prefixIcon: Icons.account_balance_rounded,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter bank name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _accountType,
                            decoration: const InputDecoration(
                              labelText: 'Account type',
                              prefixIcon: Icon(Icons.credit_card_rounded),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'salary', child: Text('Salary account')),
                              DropdownMenuItem(value: 'savings', child: Text('Savings account')),
                              DropdownMenuItem(value: 'current', child: Text('Current account')),
                            ],
                            onChanged: (value) => setState(() => _accountType = value),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select account type';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          CustomTextField(
                            controller: _accountNumberController,
                            label: 'Last 4 digits of account number',
                            hint: 'Enter last 4 digits',
                            prefixIcon: Icons.pin_outlined,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                          const SizedBox(height: AppTokens.spaceLG),
                          _SectionHeader(
                            title: 'Bank statement',
                            subtitle:
                                'Upload your latest 3-month bank statement image.',
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          Container(
                            padding: const EdgeInsets.all(AppTokens.spaceMD),
                            decoration: BoxDecoration(
                              color: AppColors.elevated,
                              borderRadius: BorderRadius.circular(AppTokens.radiusLG),
                              border: Border.all(color: AppColors.borderMid),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_bankStatementUrl != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTokens.spaceSM,
                                      vertical: AppTokens.spaceXS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(AppTokens.radiusMD),
                                      border: Border.all(
                                        color: AppColors.success.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: AppColors.success,
                                          size: 18,
                                        ),
                                        SizedBox(width: AppTokens.spaceXS),
                                        Expanded(
                                          child: Text(
                                            'Bank statement uploaded',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_bankStatementUrl != null)
                                  const SizedBox(height: AppTokens.spaceSM),
                                OutlinedButton.icon(
                                  onPressed:
                                      _isUploadingBankStatement ? null : _uploadBankStatement,
                                  icon: _isUploadingBankStatement
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Icon(
                                          _bankStatementUrl == null
                                              ? Icons.upload_file_rounded
                                              : Icons.refresh_rounded,
                                        ),
                                  label: Text(
                                    _isUploadingBankStatement
                                        ? 'Uploading...'
                                        : _bankStatementUrl == null
                                            ? 'Upload bank statement'
                                            : 'Replace bank statement',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTokens.spaceLG),
                          Container(
                            padding: const EdgeInsets.all(AppTokens.spaceMD),
                            decoration: BoxDecoration(
                              color: AppColors.elevated,
                              borderRadius: BorderRadius.circular(AppTokens.radiusLG),
                              border: Border.all(color: AppColors.borderMid),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CheckboxListTile(
                                  value: _cibilConsent,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: const Text('I consent to CIBIL and credit bureau verification.'),
                                  subtitle: const Text(
                                    'This allows the loan partner to check credit eligibility for my application.',
                                  ),
                                  onChanged: (value) => setState(() => _cibilConsent = value ?? false),
                                ),
                                const SizedBox(height: AppTokens.spaceXS),
                                CheckboxListTile(
                                  value: _communicationConsent,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: const Text('I agree to receive calls, SMS, or WhatsApp updates about my application.'),
                                  onChanged: (value) => setState(() => _communicationConsent = value ?? false),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTokens.spaceLG),
                          CustomButton(
                            text: 'Apply for loan',
                            onPressed: _submit,
                            isLoading: _isSubmitting,
                            icon: Icons.arrow_forward_rounded,
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

