import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../widgets/gradient_card.dart';
import '../../services/agent_governance_service.dart';

class AgentCouponGovernanceScreen extends StatefulWidget {
  const AgentCouponGovernanceScreen({super.key});

  @override
  State<AgentCouponGovernanceScreen> createState() =>
      _AgentCouponGovernanceScreenState();
}

class _AgentCouponGovernanceScreenState
    extends State<AgentCouponGovernanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _couponCap = 50;
  bool _couponCapLoading = true;
  bool _couponCapSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to show/hide FAB
    });
    _loadCouponCap();
  }

  Future<void> _loadCouponCap() async {
    try {
      final cap = await AgentGovernanceService.instance.getCouponCap();
      if (mounted) setState(() {
        _couponCap = cap;
        _couponCapLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _couponCap = 50;
        _couponCapLoading = false;
      });
    }
  }

  Future<void> _updateCouponCap(int value) async {
    if (_couponCapSaving) return;
    setState(() => _couponCapSaving = true);
    try {
      await AgentGovernanceService.instance.updateCouponCap(value);
      if (mounted) {
        setState(() {
          _couponCap = value;
          _couponCapSaving = false;
        });
        DialogHelper.showSuccessSnackBar(context, 'Coupon cap updated to $value%');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _couponCapSaving = false);
        DialogHelper.showErrorSnackBar(context, e.toString());
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent & Coupon Governance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'SSA', icon: Icon(Icons.support_agent_rounded)),
            Tab(
                text: 'Sales Agents',
                icon: Icon(Icons.business_center_rounded)),
            Tab(text: 'Coupons', icon: Icon(Icons.local_offer_rounded)),
          ],
        ),
      ),
      body: Container(
        decoration:
            BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
        child: TabBarView(
          controller: _tabController,
          children: [
            const SSAListTab(),
            const SalesAgentsTab(),
            CouponsTab(
              couponCap: _couponCap,
              couponCapLoading: _couponCapLoading,
              couponCapSaving: _couponCapSaving,
              onCouponCapChanged: (v) => setState(() => _couponCap = v),
              onCouponCapUpdate: _updateCouponCap,
              loadCouponCap: _loadCouponCap,
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Coupons are auto-created by discount cap per agent; no manual create.
    return null;
  }
}

// ============ SSA List Tab ============
class SSAListTab extends StatefulWidget {
  const SSAListTab({super.key});

  @override
  State<SSAListTab> createState() => _SSAListTabState();
}

class _SSAListTabState extends State<SSAListTab> {
  List<dynamic> _ssaList = [];
  bool _loading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSSAList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSSAList() async {
    setState(() => _loading = true);
    try {
      final result = await AgentGovernanceService.instance.getSSAList(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        page: _currentPage,
        limit: 20,
      );

      if (!mounted) return;
      setState(() {
        _ssaList = (result['ssaList'] as List<dynamic>?) ?? [];
        final pagination = result['pagination'] as Map<String, dynamic>?;
        _totalPages = pagination?['pages'] as int? ?? 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ssaList = [];
        _loading = false;
      });
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalOnboarding = _ssaList.fold<int>(
        0, (sum, ssa) => sum + ((ssa['onboardingCount'] as int?) ?? 0));
    final totalDiscounts = _ssaList.fold<num>(
        0, (sum, ssa) => sum + ((ssa['totalDiscounts'] as num?) ?? 0));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search SSA by name, email, or phone',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _loadSSAList();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _loadSSAList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GradientCard(
                      gradient: const LinearGradient(
                        colors: [AppColors.cardBackground, AppColors.highlight],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.people_rounded,
                            color: AppColors.textSecondary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_ssaList.length}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Total SSAs',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientCard(
                      gradient: const LinearGradient(
                        colors: [AppColors.cardBackground, AppColors.highlight],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.person_add_rounded,
                            color: AppColors.textSecondary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalOnboarding',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Onboardings',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientCard(
                      gradient: const LinearGradient(
                        colors: [AppColors.cardBackground, AppColors.highlight],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.discount_rounded,
                            color: AppColors.textSecondary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${totalDiscounts.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Discounts',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSSAList,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _ssaList.length + (_totalPages > 1 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _ssaList.length) {
                  return _buildPagination();
                }
                final ssa = _ssaList[index];
                return FadeInUp(
                  delay: Duration(milliseconds: 100 * index),
                  child: _buildSSACard(ssa),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadSSAList();
                  }
                : null,
          ),
          Text('Page $_currentPage of $_totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadSSAList();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSSACard(Map<String, dynamic> ssa) {
    final isActive = ssa['isActive'] == true;
    final name = ssa['name'] ?? 'Unknown';
    final phone = ssa['phone'] ?? 'N/A';
    final onboardingCount = ssa['onboardingCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? AppColors.green : AppColors.grey,
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: AppColors.white),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(name)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.green : AppColors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: const TextStyle(color: AppColors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        subtitle: Text(phone),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSSAMetric(
                        'Onboarded',
                        '$onboardingCount',
                        Icons.person_add_rounded,
                        AppColors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildSSAMetric(
                        'Pincode',
                        ssa['pincode'] ?? 'N/A',
                        Icons.location_on_rounded,
                        AppColors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildSSAMetric(
                        'City',
                        ssa['city'] ?? 'N/A',
                        Icons.location_city_rounded,
                        AppColors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewSSADetails(ssa),
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewSSACoupons(ssa),
                        icon: const Icon(Icons.local_offer_rounded),
                        label: const Text('View Coupons'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSSAMetric(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _viewSSADetails(Map<String, dynamic> ssa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ssa['name'] ?? 'Unknown'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Phone', ssa['phone'] ?? 'N/A'),
            _buildDetailRow('Email', ssa['email'] ?? 'N/A'),
            _buildDetailRow('Pincode', ssa['pincode'] ?? 'N/A'),
            _buildDetailRow('City', ssa['city'] ?? 'N/A'),
            _buildDetailRow('State', ssa['state'] ?? 'N/A'),
            _buildDetailRow(
                'Status', ssa['isActive'] == true ? 'Active' : 'Inactive'),
            _buildDetailRow(
                'Onboarding Count', '${ssa['onboardingCount'] ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _viewSSACoupons(Map<String, dynamic> ssa) {
    // TODO: Navigate to coupons filtered by SSA
    DialogHelper.showInfoSnackBar(
      context,
      'Showing coupons for ${ssa['name']}',
    );
  }
}

// ============ Sales Agents Tab ============
class SalesAgentsTab extends StatefulWidget {
  const SalesAgentsTab({super.key});

  @override
  State<SalesAgentsTab> createState() => _SalesAgentsTabState();
}

class _SalesAgentsTabState extends State<SalesAgentsTab> {
  List<dynamic> _agents = [];
  bool _loading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAgents() async {
    setState(() => _loading = true);
    try {
      final result =
          await AgentGovernanceService.instance.getCompanySalesAgentList(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        page: _currentPage,
        limit: 20,
      );

      if (!mounted) return;
      setState(() {
        _agents = (result['csaList'] as List<dynamic>?) ?? [];
        final pagination = result['pagination'] as Map<String, dynamic>?;
        _totalPages = pagination?['pages'] as int? ?? 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _agents = [];
        _loading = false;
      });
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalOnboarding = _agents.fold<int>(
        0, (sum, agent) => sum + ((agent['onboardingCount'] as int?) ?? 0));
    final totalDiscounts = _agents.fold<num>(
        0, (sum, agent) => sum + ((agent['totalDiscounts'] as num?) ?? 0));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search agents by name, email, or phone',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _loadAgents();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _loadAgents(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GradientCard(
                      gradient: AppColors.primaryGradient,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.business_center_rounded,
                            color: AppColors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_agents.length}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Sales Agents',
                            style: TextStyle(color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientCard(
                      gradient: AppColors.primaryGradient,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.person_add_rounded,
                            color: AppColors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalOnboarding',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Onboardings',
                            style: TextStyle(color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientCard(
                      gradient: AppColors.primaryGradient,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.discount_rounded,
                            color: AppColors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${totalDiscounts.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Discounts',
                            style: TextStyle(color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAgents,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _agents.length + (_totalPages > 1 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _agents.length) {
                  return _buildPagination();
                }
                final agent = _agents[index];
                return FadeInUp(
                  delay: Duration(milliseconds: 100 * index),
                  child: _buildAgentCard(agent),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadAgents();
                  }
                : null,
          ),
          Text('Page $_currentPage of $_totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadAgents();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> agent) {
    final isActive = agent['isActive'] == true;
    final name = (agent['name'] as String? ?? 'Unknown').trim();
    final phone = (agent['phone'] as String? ?? '').trim();
    final region = (agent['region'] as String? ?? '').trim();
    final hasRegion = region.isNotEmpty;
    final onboardingCount = agent['onboardingCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? AppColors.accent.withValues(alpha: 0.18)
              : AppColors.cardBackground,
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(name)),
            if (hasRegion)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  region,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(phone.isEmpty ? '-' : phone),
            Text('Onboarded: $onboardingCount shopkeepers'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () => _showAgentOptions(agent),
        ),
      ),
    );
  }

  void _showAgentOptions(Map<String, dynamic> agent) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility_rounded),
            title: const Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              _viewAgentDetails(agent);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_rounded),
            title: const Text('View Onboarded Shopkeepers'),
            onTap: () {
              Navigator.pop(context);
              DialogHelper.showInfoSnackBar(
                context,
                'Showing shopkeepers onboarded by ${agent['name']}',
              );
            },
          ),
        ],
      ),
    );
  }

  void _viewAgentDetails(Map<String, dynamic> agent) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final name = (agent['name'] as String? ?? 'Unknown').trim();
        return AlertDialog(
        title: Text(
          name.isEmpty ? 'Sales agent' : name,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Phone', _valueOrDash(agent['phone'])),
            _buildDetailRow('Email', _valueOrDash(agent['email'])),
            _buildDetailRow('Region', _valueOrDash(agent['region'])),
            _buildDetailRow('Territory', _valueOrDash(agent['territory'])),
            _buildDetailRow('Pincode', _valueOrDash(agent['pincode'])),
            _buildDetailRow(
                'Status', agent['isActive'] == true ? 'Active' : 'Inactive'),
            _buildDetailRow(
                'Onboarding Count', '${agent['onboardingCount'] ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );},
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _valueOrDash(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    return s.isEmpty ? '-' : s;
  }
}

// ============ Coupons Tab ============
class CouponsTab extends StatefulWidget {
  const CouponsTab({
    super.key,
    required this.couponCap,
    required this.couponCapLoading,
    required this.couponCapSaving,
    required this.onCouponCapChanged,
    required this.onCouponCapUpdate,
    required this.loadCouponCap,
  });

  final int couponCap;
  final bool couponCapLoading;
  final bool couponCapSaving;
  final void Function(int) onCouponCapChanged;
  final void Function(int) onCouponCapUpdate;
  final Future<void> Function() loadCouponCap;

  @override
  State<CouponsTab> createState() => _CouponsTabState();
}

class _CouponsTabState extends State<CouponsTab> {
  bool _loading = true;
  int _totalCount = 0;
  num _totalDiscounts = 0;

  num _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _loading = true);
    try {
      final result = await AgentGovernanceService.instance.getCouponList(
        page: 1,
        limit: 20,
      );

      if (!mounted) return;
      final list = (result['coupons'] as List<dynamic>?) ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final total = pagination?['total'] as int?;
      final pages = pagination?['pages'] as int? ?? 1;
      setState(() {
        _totalCount = total ?? (pages * 20);
        _totalDiscounts = list.fold<num>(0, (sum, c) => sum + _parseNum(c['discountValue']));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _totalCount = 0;
        _totalDiscounts = 0;
        _loading = false;
      });
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  Widget _buildCouponCapBar() {
    final theme = Theme.of(context);
    if (widget.couponCapLoading) {
      return Padding(
        padding: const EdgeInsets.all(AppTokens.spaceMD),
        child: Card(
          color: AppColors.cardBackground,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceMD),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppTokens.spaceMD),
                Text(
                  'Loading coupon cap…',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.spaceMD, AppTokens.spaceSM, AppTokens.spaceMD, 0),
      child: Card(
        color: AppColors.cardBackground,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.percent_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: AppTokens.spaceSM),
                  Expanded(
                    child: Text(
                      'Maximum discount cap for coupons (all agents)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spaceXS),
              Text(
                'Coupons are auto-created in steps (5%, 10%, …) up to this cap for every SSA and Sales Agent.',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppTokens.spaceSM),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: widget.couponCap.toDouble(),
                      min: 10,
                      max: 90,
                      divisions: 8,
                      label: '${widget.couponCap}%',
                      onChanged: widget.couponCapSaving
                          ? null
                          : (v) => widget.onCouponCapChanged(v.round().clamp(10, 90)),
                      onChangeEnd: widget.couponCapSaving
                          ? null
                          : (v) => widget.onCouponCapUpdate(v.round().clamp(10, 90)),
                      activeColor: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: AppTokens.spaceSM),
                  Text(
                    '${widget.couponCap}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCouponCapBar(),
        if (_loading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCoupons,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GradientCard(
                            gradient: AppColors.primaryGradient,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.local_offer_rounded,
                                  color: AppColors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$_totalCount',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Total Coupons',
                                  style: TextStyle(color: AppColors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GradientCard(
                            gradient: const LinearGradient(
                              colors: [AppColors.orange, AppColors.deepOrange],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.currency_rupee_rounded,
                                  color: AppColors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${_totalDiscounts.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Discount (sample)',
                                  style: TextStyle(color: AppColors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
