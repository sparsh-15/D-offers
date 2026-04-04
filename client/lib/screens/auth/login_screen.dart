import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/revamp/login_revamp_theme.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';
import '../role_selection/role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final FocusNode _mobileFocusNode = FocusNode();
  bool _isLoading = false;
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    _mobileFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 430).clamp(0.85, 1.0);
    final sidePad = 24.0 * scale;
    final heroTitleSize = 37.0 * scale;
    final brandSize = 28.5 * scale;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                LoginRevampColors.topStart,
                LoginRevampColors.topEnd,
              ],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardMinHeight = constraints.maxHeight * 0.55;

                    return Stack(
                      children: [
                        Positioned(
                          left: sidePad,
                          right: sidePad,
                          top: 0,
                          bottom: cardMinHeight - (20 * scale),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 46 * scale,
                                    height: 46 * scale,
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
                                        size: 21,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10 * scale),
                                  Text.rich(
                                    TextSpan(
                                      style: LoginRevampTypography.sectionTitle
                                          .copyWith(
                                        color: Colors.white,
                                        fontSize: brandSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      children: [
                                        const TextSpan(text: 'My'),
                                        TextSpan(
                                          text: 'Offers',
                                          style: LoginRevampTypography
                                              .sectionTitle
                                              .copyWith(
                                            color: LoginRevampColors.accent,
                                            fontSize: brandSize,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24 * scale),
                              Text.rich(
                                TextSpan(
                                  style: LoginRevampTypography.brand.copyWith(
                                    fontSize: heroTitleSize,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Discover '),
                                    TextSpan(
                                      text: 'Local',
                                      style: LoginRevampTypography.brandAccent
                                          .copyWith(
                                        fontSize: heroTitleSize,
                                        height: 1.15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const TextSpan(text: '\nDeals Near You'),
                                  ],
                                ),
                              ),
                              SizedBox(height: 14 * scale),
                              Text(
                                'Exclusive savings from shops in your neighbourhood -\nclaimed in seconds.',
                                style: LoginRevampTypography.subcopy.copyWith(
                                  fontSize: 13.0 * scale,
                                ),
                              ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedPadding(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            padding: EdgeInsets.only(
                              bottom: keyboardInset > 0 ? keyboardInset : 0,
                            ),
                            child: SizedBox(
                              height: cardMinHeight,
                              width: double.infinity,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onVerticalDragEnd: (details) {
                                  final velocity = details.primaryVelocity ?? 0;
                                  if (velocity < -120) {
                                    _mobileFocusNode.requestFocus();
                                  } else if (velocity > 120) {
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                                child: Container(
                        decoration: BoxDecoration(
                          color: LoginRevampColors.panel,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 30,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(
                          sidePad,
                          28 * scale,
                          sidePad,
                          8 * scale,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sign In',
                              style: LoginRevampTypography.sectionTitle.copyWith(
                                fontSize: 38 * scale,
                              ),
                            ),
                            SizedBox(height: 4 * scale),
                            Text(
                              'Enter your mobile number to continue',
                              style: LoginRevampTypography.sectionSubtitle.copyWith(
                                fontSize: 14 * scale,
                              ),
                            ),
                            SizedBox(height: 22 * scale),
                            Text(
                              'MOBILE NUMBER',
                              style: LoginRevampTypography.fieldLabel.copyWith(
                                fontSize: 12 * scale,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            Container(
                              height: 58,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: LoginRevampColors.fieldBorder),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.smartphone_outlined,
                                    color: LoginRevampColors.textMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '+91',
                                    style: LoginRevampTypography.body.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      focusNode: _mobileFocusNode,
                                      keyboardType: TextInputType.phone,
                                      maxLength: 10,
                                      onChanged: (_) {
                                        if (_phoneError != null) {
                                          setState(() => _phoneError = null);
                                        }
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      style: LoginRevampTypography.body
                                          .copyWith(fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'XXXXX XXXXX',
                                        hintStyle: LoginRevampTypography.body
                                            .copyWith(fontSize: 14),
                                        counterText: '',
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_phoneError != null) ...[
                              SizedBox(height: 6 * scale),
                              Text(
                                _phoneError!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            SizedBox(height: 18 * scale),
                            SizedBox(
                              height: 62,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: LoginRevampColors.accent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: const StadiumBorder(),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Get OTP',
                                            style: LoginRevampTypography.button
                                                .copyWith(
                                              fontSize: 16 * scale,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            SizedBox(height: 18 * scale),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'New user? ',
                                  style: LoginRevampTypography.body.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RoleSelectionScreen(),
                                    ),
                                  ),
                                  child: Text(
                                    'Create account',
                                    style: LoginRevampTypography.body.copyWith(
                                      fontSize: 14,
                                      color: LoginRevampColors.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            SizedBox(height: 10 * scale),
                            const Divider(
                              color: LoginRevampColors.fieldBorder,
                              height: 1,
                            ),
                            SizedBox(height: 10 * scale),
                            Text(
                              AppStrings.companyName,
                              textAlign: TextAlign.center,
                              style: LoginRevampTypography.footerTitle.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2 * scale),
                            Text(
                              AppStrings.supportEmail,
                              textAlign: TextAlign.center,
                              style: LoginRevampTypography.footerSubtitle.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                              ),
                              ),
                            ),
                          ),
                          ),
                        ],
                      );
                    },
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  String? _validatePhoneInput(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Please enter mobile number';
    }
    if (trimmed.length != 10) {
      return 'Enter a valid 10-digit number';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    final validationMessage = _validatePhoneInput(_phoneController.text);
    if (validationMessage != null) {
      setState(() => _phoneError = validationMessage);
      return;
    }

    if (_phoneError != null) {
      setState(() => _phoneError = null);
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.sendOtp(phone: _phoneController.text);
      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(context, 'OTP sent successfully');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneNumber: _phoneController.text,
            isRegistration: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final err = e.toString().toLowerCase();
      if (err.contains('too many') || err.contains('429')) {
        DialogHelper.showErrorSnackBar(
          context,
          'Too many attempts. Please wait 15 minutes.',
        );
      } else if (err.contains('not found') ||
          err.contains('account not found') ||
          err.contains('please signup')) {
        DialogHelper.showErrorSnackBar(
          context,
          'Account not found. Please register.',
        );
      } else {
        DialogHelper.showErrorSnackBar(
          context,
          err.replaceFirst('exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
