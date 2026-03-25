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
    _descriptionController.dispose();
    _discountValueController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _loadAgents() async {
    setState(() => _loadingAgents = true);
    try {
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
                'maxCouponDiscountPercent':
                    (agent['maxCouponDiscountPercent'] as num?)?.toInt() ?? 50,
              }),
          ...salesList.map((agent) => {
                'id': agent['_id'] ?? agent['id'],
                'name': agent['name'] ?? 'Unknown',
                'phone': agent['phone'] ?? '',
                'type': 'Sales Agent',
                'maxCouponDiscountPercent':
                    (agent['maxCouponDiscountPercent'] as num?)?.toInt() ?? 50,
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
    const sectionGap = 20.0;
    const innerGap = 14.0;

    final selectedAgent = _agents.firstWhere(
      (agent) => agent['id'] == _selectedAgentId,
      orElse: () => const <String, dynamic>{},
    );
    final selectedAgentMaxDiscount =
        (selectedAgent['maxCouponDiscountPercent'] as int?) ?? 50;

    return Scaffold(
      appBar: AppBar(
        leading: ThemeHelper.buildBackButton(context),
        title: const Text('Create Coupon'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
      ),
      body: Container(
        decoration:
            BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
        child: _loadingAgents
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                    'Coupon Details',
                                    'Code is generated automatically from agent and discount.',
                                  ),
                                  const SizedBox(height: innerGap),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: const Text(
                                      'For percentage coupons, the last 2 characters represent discount (e.g. 20 => 20%).',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(height: innerGap),
                                  TextFormField(
                                    controller: _descriptionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Description (Optional)',
                                      hintText:
                                          'e.g., Welcome discount for new users',
                                      prefixIcon:
                                          Icon(Icons.description_rounded),
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: sectionGap),
                            _buildSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                    'Discount Configuration',
                                    'Choose value within selected agent cap.',
                                  ),
                                  const SizedBox(height: innerGap),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: _discountType,
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
                                        child: Text('Fixed Amount (INR)'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _discountType = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: innerGap),
                                  TextFormField(
                                    controller: _discountValueController,
                                    decoration: InputDecoration(
                                      labelText: _discountType == 'percentage'
                                          ? 'Discount Percentage (Max $selectedAgentMaxDiscount%)'
                                          : 'Discount Amount',
                                      hintText: _discountType == 'percentage'
                                          ? 'Enter 1 to $selectedAgentMaxDiscount'
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
                                          numValue > selectedAgentMaxDiscount) {
                                        return 'Percentage cannot exceed agent max ($selectedAgentMaxDiscount%)';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: sectionGap),
                            _buildSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                    'Agent Assignment',
                                    'Select the owner of this coupon.',
                                  ),
                                  const SizedBox(height: innerGap),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: _selectedAgentId,
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
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.success
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.success
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Text(
                                      'Selected agent max percentage discount: $selectedAgentMaxDiscount%',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: sectionGap),
                            _buildSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                    'Additional Settings',
                                    'Optional controls for expiry and usage.',
                                  ),
                                  const SizedBox(height: innerGap),
                                  OutlinedButton.icon(
                                    onPressed: _selectExpiryDate,
                                    icon: const Icon(
                                        Icons.calendar_today_rounded),
                                    label: Text(
                                      _expiryDate == null
                                          ? 'Set Expiry Date (Optional)'
                                          : 'Expires: ${DateFormat('MMM d, y').format(_expiryDate!)}',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize:
                                          const Size(double.infinity, 48),
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
                                  const SizedBox(height: innerGap),
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
                                  _isLoading ? 'Creating...' : 'Create Coupon',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.highlight,
                                  foregroundColor: AppColors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
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
                ),
              ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }
}
