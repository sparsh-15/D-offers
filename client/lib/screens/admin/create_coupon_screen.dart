import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/agent_governance_service.dart';

class CreateCouponScreen extends StatefulWidget {
  const CreateCouponScreen({super.key});

  @override
  State<CreateCouponScreen> createState() => _CreateCouponScreenState();
}

class _CreateCouponScreenState extends State<CreateCouponScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _maxUsesController = TextEditingController();

  String _discountType = 'percentage';
  String? _selectedAgentId;
  DateTime? _expiryDate;
  bool _isLoading = false;

  List<Map<String, dynamic>> _agents = [];
  bool _loadingAgents = true;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _loadAgents() async {
    setState(() => _loadingAgents = true);
    try {
      // Load both SSA and Company Sales Agents
      final ssaResult = await AgentGovernanceService.instance.getSSAList(
        page: 1,
        limit: 100,
      );
      final salesResult =
          await AgentGovernanceService.instance.getCompanySalesAgentList(
        page: 1,
        limit: 100,
      );

      if (!mounted) return;
      setState(() {
        final ssaList = (ssaResult['ssaList'] as List<dynamic>?) ?? [];
        final salesList = (salesResult['csaList'] as List<dynamic>?) ?? [];

        _agents = [
          ...ssaList.map((agent) => {
                'id': agent['_id'] ?? agent['id'],
                'name': agent['name'] ?? 'Unknown',
                'phone': agent['phone'] ?? '',
                'type': 'SSA',
              }),
          ...salesList.map((agent) => {
                'id': agent['_id'] ?? agent['id'],
                'name': agent['name'] ?? 'Unknown',
                'phone': agent['phone'] ?? '',
                'type': 'Sales Agent',
              }),
        ];
        _loadingAgents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingAgents = false);
      DialogHelper.showErrorSnackBar(context, 'Failed to load agents: $e');
    }
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _createCoupon() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAgentId == null) {
      DialogHelper.showErrorSnackBar(context, 'Please select an agent');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AgentGovernanceService.instance.createCoupon(
        code: _codeController.text.trim().toUpperCase(),
        discountType: _discountType,
        discountValue: num.parse(_discountValueController.text),
        agentId: _selectedAgentId!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        expiryDate: _expiryDate,
        maxUses: _maxUsesController.text.isEmpty
            ? null
            : int.parse(_maxUsesController.text),
      );

      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(context, 'Coupon created successfully!');
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
        title: const Text('Create Coupon'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Container(
        decoration:
            BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
        child: _loadingAgents
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                              const Text(
                                'Coupon Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _codeController,
                                decoration: const InputDecoration(
                                  labelText: 'Coupon Code',
                                  hintText: 'e.g., WELCOME50',
                                  prefixIcon:
                                      Icon(Icons.confirmation_number_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                textCapitalization:
                                    TextCapitalization.characters,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a coupon code';
                                  }
                                  if (value.length < 3) {
                                    return 'Code must be at least 3 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description (Optional)',
                                  hintText:
                                      'e.g., Welcome discount for new users',
                                  prefixIcon: Icon(Icons.description_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
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
                              const Text(
                                'Discount Configuration',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _discountType,
                                decoration: const InputDecoration(
                                  labelText: 'Discount Type',
                                  prefixIcon: Icon(Icons.discount_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'percentage',
                                    child: Text('Percentage (%)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'fixed',
                                    child: Text('Fixed Amount (₹)'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _discountType = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _discountValueController,
                                decoration: InputDecoration(
                                  labelText: _discountType == 'percentage'
                                      ? 'Discount Percentage'
                                      : 'Discount Amount',
                                  hintText: _discountType == 'percentage'
                                      ? 'e.g., 10'
                                      : 'e.g., 100',
                                  prefixIcon: Icon(
                                    _discountType == 'percentage'
                                        ? Icons.percent_rounded
                                        : Icons.currency_rupee_rounded,
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter discount value';
                                  }
                                  final numValue = num.tryParse(value);
                                  if (numValue == null || numValue <= 0) {
                                    return 'Please enter a valid positive number';
                                  }
                                  if (_discountType == 'percentage' &&
                                      numValue > 100) {
                                    return 'Percentage cannot exceed 100';
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
                              const Text(
                                'Agent Assignment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedAgentId,
                                decoration: const InputDecoration(
                                  labelText: 'Select Agent',
                                  prefixIcon: Icon(Icons.person_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                items: _agents.map((agent) {
                                  return DropdownMenuItem<String>(
                                    value: agent['id'],
                                    child: Text(
                                      '${agent['name']} (${agent['type']})',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAgentId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select an agent';
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
                              const Text(
                                'Additional Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _selectExpiryDate,
                                icon: const Icon(Icons.calendar_today_rounded),
                                label: Text(
                                  _expiryDate == null
                                      ? 'Set Expiry Date (Optional)'
                                      : 'Expires: ${DateFormat('MMM d, y').format(_expiryDate!)}',
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                              ),
                              if (_expiryDate != null) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _expiryDate = null;
                                    });
                                  },
                                  icon: const Icon(Icons.clear_rounded),
                                  label: const Text('Clear Expiry Date'),
                                ),
                              ],
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _maxUsesController,
                                decoration: const InputDecoration(
                                  labelText: 'Max Uses (Optional)',
                                  hintText: 'Leave empty for unlimited',
                                  prefixIcon: Icon(Icons.numbers_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final numValue = int.tryParse(value);
                                    if (numValue == null || numValue <= 0) {
                                      return 'Please enter a valid positive number';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _createCoupon,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Icon(Icons.add_rounded),
                          label: Text(
                              _isLoading ? 'Creating...' : 'Create Coupon'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
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
