import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/agent_governance_service.dart';
import '../../services/pincode_service.dart';

class CreateSalesAgentScreen extends StatefulWidget {
  const CreateSalesAgentScreen({super.key});

  @override
  State<CreateSalesAgentScreen> createState() => _CreateSalesAgentScreenState();
}

class _CreateSalesAgentScreenState extends State<CreateSalesAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pincodeController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _loadingPincode = false;

  String? _state;
  String? _city;
  String? _selectedArea;
  List<String> _areas = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchPincodeDetails() async {
    final pincode = _pincodeController.text.trim();

    if (pincode.length != 6) {
      return;
    }

    setState(() {
      _loadingPincode = true;
      _state = null;
      _city = null;
      _selectedArea = null;
      _areas = [];
    });

    try {
      final details = await PincodeService.instance.getPincodeDetails(pincode);

      if (details != null && mounted) {
        setState(() {
          _state = details['state'] as String?;
          _city = details['city'] as String?;
          _areas = (details['areas'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          _loadingPincode = false;
        });

        DialogHelper.showSuccessSnackBar(
          context,
          'Location details fetched successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingPincode = false);
        DialogHelper.showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _createSalesAgent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AgentGovernanceService.instance.createCompanySalesAgent(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        region: _selectedArea,
        territory: _city,
        pincode: _pincodeController.text.trim().isEmpty
            ? null
            : _pincodeController.text.trim(),
      );

      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(
          context, 'Company Sales Agent created successfully!');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Company Sales Agent'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Container(
        decoration:
            BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.business_center_rounded,
                                color: AppColors.accent),
                            const SizedBox(width: 8),
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'e.g., Vikram Singh',
                            prefixIcon: Icon(Icons.person_rounded),
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter full name';
                            }
                            if (value.length < 3) {
                              return 'Name must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'e.g., vikram@company.com',
                            prefixIcon: Icon(Icons.email_rounded),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email address';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'e.g., 9876543210',
                            prefixIcon: Icon(Icons.phone_rounded),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter phone number';
                            }
                            if (value.length != 10) {
                              return 'Phone number must be 10 digits';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return 'Please enter only numbers';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock_rounded, color: AppColors.accent),
                            const SizedBox(width: 8),
                            const Text(
                              'Account Security',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter a strong password',
                            prefixIcon: const Icon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                color: AppColors.accent),
                            const SizedBox(width: 8),
                            const Text(
                              'Territory Information (Optional)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _pincodeController,
                          decoration: InputDecoration(
                            labelText: 'Pincode',
                            hintText: 'e.g., 110001',
                            prefixIcon: const Icon(Icons.pin_drop_rounded),
                            suffixIcon: _loadingPincode
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.search_rounded),
                                    onPressed: _fetchPincodeDetails,
                                  ),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          onChanged: (value) {
                            if (value.length == 6) {
                              _fetchPincodeDetails();
                            }
                          },
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (value.length != 6) {
                                return 'Pincode must be 6 digits';
                              }
                              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                return 'Please enter only numbers';
                              }
                            }
                            return null;
                          },
                        ),
                        if (_state != null) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _state,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              prefixIcon: Icon(Icons.map_rounded),
                              border: OutlineInputBorder(),
                            ),
                            enabled: false,
                          ),
                        ],
                        if (_city != null) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _city,
                            decoration: const InputDecoration(
                              labelText: 'Territory/District',
                              prefixIcon: Icon(Icons.location_city_rounded),
                              border: OutlineInputBorder(),
                            ),
                            enabled: false,
                          ),
                        ],
                        if (_areas.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedArea,
                            decoration: const InputDecoration(
                              labelText: 'Region/Area',
                              prefixIcon: Icon(Icons.place_rounded),
                              border: OutlineInputBorder(),
                            ),
                            items: _areas.map((area) {
                              return DropdownMenuItem(
                                value: area,
                                child: Text(area),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedArea = value;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createSalesAgent,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_rounded),
                    label:
                        Text(_isLoading ? 'Creating...' : 'Create Sales Agent'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
