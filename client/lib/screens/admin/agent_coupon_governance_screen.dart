import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../widgets/gradient_card.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
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
          children: const [
            SSAListTab(),
            SalesAgentsTab(),
            CouponsTab(),
          ],
        ),
      ),
    );
  }
}

// ============ SSA List Tab ============
class SSAListTab extends StatefulWidget {
  const SSAListTab({super.key});

  @override
  State<SSAListTab> createState() => _SSAListTabState();
}

class _SSAListTabState extends State<SSAListTab> {
  List<Map<String, dynamic>> _ssaList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSSAList();
  }

  Future<void> _loadSSAList() async {
    setState(() => _loading = true);
    try {
      // TODO: Call API to get SSA list
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _ssaList = [
          {
            'id': '1',
            'name': 'Rajesh Kumar',
            'phone': '9876543210',
            'email': 'rajesh@example.com',
            'onboardingCount': 25,
            'totalCoupons': 50,
            'activeCoupons': 30,
            'status': 'active',
          },
          {
            'id': '2',
            'name': 'Priya Sharma',
            'phone': '9876543211',
            'email': 'priya@example.com',
            'onboardingCount': 18,
            'totalCoupons': 40,
            'activeCoupons': 25,
            'status': 'active',
          },
          {
            'id': '3',
            'name': 'Amit Patel',
            'phone': '9876543212',
            'email': 'amit@example.com',
            'onboardingCount': 12,
            'totalCoupons': 30,
            'activeCoupons': 15,
            'status': 'inactive',
          },
        ];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalOnboarding = _ssaList.fold<int>(
        0, (sum, ssa) => sum + (ssa['onboardingCount'] as int));
    final totalCoupons =
        _ssaList.fold<int>(0, (sum, ssa) => sum + (ssa['totalCoupons'] as int));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: GradientCard(
                      gradient: AppColors.primaryGradient,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.people_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_ssaList.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Total SSAs',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientCard(
                      gradient: AppColors.accentGradient,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalOnboarding',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Onboardings',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientCard(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.local_offer_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalCoupons',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Coupons',
                            style: TextStyle(color: Colors.white),
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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _ssaList.length,
            itemBuilder: (context, index) {
              final ssa = _ssaList[index];
              return FadeInUp(
                delay: Duration(milliseconds: 100 * index),
                child: _buildSSACard(ssa),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSSACard(Map<String, dynamic> ssa) {
    final isActive = ssa['status'] == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.grey,
          child: Text(
            ssa['name'].toString().substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(ssa['name'])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        subtitle: Text(ssa['phone']),
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
                        '${ssa['onboardingCount']}',
                        Icons.person_add_rounded,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildSSAMetric(
                        'Total Coupons',
                        '${ssa['totalCoupons']}',
                        Icons.local_offer_rounded,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildSSAMetric(
                        'Active',
                        '${ssa['activeCoupons']}',
                        Icons.check_circle_rounded,
                        Colors.green,
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
                          foregroundColor: Colors.white,
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
            color: Colors.grey[600],
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
        title: Text(ssa['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Phone', ssa['phone']),
            _buildDetailRow('Email', ssa['email']),
            _buildDetailRow('Status', ssa['status']),
            _buildDetailRow('Onboarding Count', '${ssa['onboardingCount']}'),
            _buildDetailRow('Total Coupons', '${ssa['totalCoupons']}'),
            _buildDetailRow('Active Coupons', '${ssa['activeCoupons']}'),
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
  List<Map<String, dynamic>> _agents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    setState(() => _loading = true);
    try {
      // TODO: Call API to get company sales agents
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _agents = [
          {
            'id': '1',
            'name': 'Vikram Singh',
            'phone': '9876543220',
            'email': 'vikram@company.com',
            'onboardingCount': 35,
            'region': 'North',
            'status': 'active',
          },
          {
            'id': '2',
            'name': 'Sneha Reddy',
            'phone': '9876543221',
            'email': 'sneha@company.com',
            'onboardingCount': 28,
            'region': 'South',
            'status': 'active',
          },
        ];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalOnboarding = _agents.fold<int>(
        0, (sum, agent) => sum + (agent['onboardingCount'] as int));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: GradientCard(
                  gradient: AppColors.primaryGradient,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.business_center_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_agents.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Sales Agents',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientCard(
                  gradient: AppColors.accentGradient,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$totalOnboarding',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Total Onboardings',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _agents.length,
            itemBuilder: (context, index) {
              final agent = _agents[index];
              return FadeInUp(
                delay: Duration(milliseconds: 100 * index),
                child: _buildAgentCard(agent),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> agent) {
    final isActive = agent['status'] == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.blue : Colors.grey,
          child: Text(
            agent['name'].toString().substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(agent['name'])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                agent['region'],
                style: const TextStyle(color: Colors.blue, fontSize: 12),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(agent['phone']),
            Text('Onboarded: ${agent['onboardingCount']} shopkeepers'),
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
      builder: (context) => AlertDialog(
        title: Text(agent['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Phone', agent['phone']),
            _buildDetailRow('Email', agent['email']),
            _buildDetailRow('Region', agent['region']),
            _buildDetailRow('Status', agent['status']),
            _buildDetailRow('Onboarding Count', '${agent['onboardingCount']}'),
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
}

// ============ Coupons Tab ============
class CouponsTab extends StatefulWidget {
  const CouponsTab({super.key});

  @override
  State<CouponsTab> createState() => _CouponsTabState();
}

class _CouponsTabState extends State<CouponsTab> {
  List<Map<String, dynamic>> _coupons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _loading = true);
    try {
      // TODO: Call API to get all coupons
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _coupons = [
          {
            'id': '1',
            'code': 'WELCOME50',
            'discount': 50,
            'type': 'percentage',
            'ssaName': 'Rajesh Kumar',
            'activations': 15,
            'totalDiscount': 7500,
            'status': 'active',
          },
          {
            'id': '2',
            'code': 'FLAT200',
            'discount': 200,
            'type': 'fixed',
            'ssaName': 'Priya Sharma',
            'activations': 10,
            'totalDiscount': 2000,
            'status': 'active',
          },
          {
            'id': '3',
            'code': 'EXPIRED10',
            'discount': 10,
            'type': 'percentage',
            'ssaName': 'Amit Patel',
            'activations': 5,
            'totalDiscount': 500,
            'status': 'expired',
          },
        ];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalActivations = _coupons.fold<int>(
        0, (sum, coupon) => sum + (coupon['activations'] as int));
    final totalDiscount = _coupons.fold<int>(
        0, (sum, coupon) => sum + (coupon['totalDiscount'] as int));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_coupons.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Total Coupons',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientCard(
                      gradient: AppColors.accentGradient,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalActivations',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Activations',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientCard(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.currency_rupee_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹$totalDiscount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Total Discount',
                            style: TextStyle(color: Colors.white),
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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _coupons.length,
            itemBuilder: (context, index) {
              final coupon = _coupons[index];
              return FadeInUp(
                delay: Duration(milliseconds: 100 * index),
                child: _buildCouponCard(coupon),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final isActive = coupon['status'] == 'active';
    final isPercentage = coupon['type'] == 'percentage';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    coupon['code'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Expired',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const Spacer(),
                Text(
                  isPercentage
                      ? '${coupon['discount']}% OFF'
                      : '₹${coupon['discount']} OFF',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'SSA: ${coupon['ssaName']}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCouponMetric(
                    'Activations',
                    '${coupon['activations']}',
                    Icons.check_circle_rounded,
                  ),
                ),
                Expanded(
                  child: _buildCouponMetric(
                    'Total Discount',
                    '₹${coupon['totalDiscount']}',
                    Icons.currency_rupee_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
