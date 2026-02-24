import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/agent_governance_service.dart';

class CouponActivationsScreen extends StatefulWidget {
  const CouponActivationsScreen({super.key});

  @override
  State<CouponActivationsScreen> createState() =>
      _CouponActivationsScreenState();
}

class _CouponActivationsScreenState extends State<CouponActivationsScreen> {
  List<dynamic> _activations = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  num _totalDiscounts = 0;
  final TextEditingController _couponCodeController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadActivations();
  }

  @override
  void dispose() {
    _couponCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadActivations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AgentGovernanceService.instance.getCouponActivations(
        couponCode: _couponCodeController.text.isEmpty
            ? null
            : _couponCodeController.text,
        startDate: _startDate,
        endDate: _endDate,
        page: _currentPage,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _activations = result['activations'] as List<dynamic>;
          _totalPages = result['totalPages'] as int;
          _totalDiscounts = result['totalDiscounts'] as num? ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onFilter() {
    setState(() {
      _currentPage = 1;
    });
    _loadActivations();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _onFilter();
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _onFilter();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeHelper.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        appBar: AppBar(
          leading: ThemeHelper.buildBackButton(context),
          backgroundColor: AppColors.transparent,
          elevation: 0,
          title: const Text('Coupon Activations'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadActivations,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildFilters(isDark, theme),
            _buildSummary(isDark, theme),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 64, color: AppColors.error),
                              const SizedBox(height: 16),
                              Text('Error: $_error'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadActivations,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _activations.isEmpty
                          ? const Center(
                              child: Text('No coupon activations found'))
                          : RefreshIndicator(
                              onRefresh: _loadActivations,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _activations.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _activations.length) {
                                    return _buildPagination(theme);
                                  }
                                  return _buildActivationCard(
                                      _activations[index], isDark, theme);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _couponCodeController,
            decoration: InputDecoration(
              hintText: 'Search by coupon code',
              prefixIcon: const Icon(Icons.confirmation_number_rounded),
              suffixIcon: _couponCodeController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _couponCodeController.clear();
                        _onFilter();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _onFilter(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range_rounded),
                  label: Text(
                    _startDate != null && _endDate != null
                        ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}'
                        : 'Select Date Range',
                  ),
                ),
              ),
              if (_startDate != null && _endDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: _clearDateRange,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.discount_rounded,
              color: AppColors.success,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Discounts Distributed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_totalDiscounts.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivationCard(
      Map<String, dynamic> activation, bool isDark, ThemeData theme) {
    final couponCode = activation['couponCode'] as String? ?? 'N/A';
    final shopName = activation['shopName'] as String? ?? 'N/A';
    final agentName = activation['agentName'] as String? ?? 'N/A';
    final discountAmount = activation['discountAmount'] as num? ?? 0;
    final activatedAt = activation['activatedAt'] as String?;
    final subscriptionPlan = activation['subscriptionPlan'] as String? ?? 'N/A';

    DateTime? activationDate;
    if (activatedAt != null) {
      try {
        activationDate = DateTime.parse(activatedAt);
      } catch (e) {
        // Handle parse error
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
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
                  color: AppColors.info.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.confirmation_number_rounded,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      couponCode,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${discountAmount.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.store_rounded,
            'Shop',
            shopName,
            theme,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.person_rounded,
            'Agent',
            agentName,
            theme,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.subscriptions_rounded,
            'Plan',
            subscriptionPlan,
            theme,
          ),
          if (activationDate != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today_rounded,
              'Activated',
              DateFormat('MMM d, y - h:mm a').format(activationDate),
              theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.textTheme.bodySmall?.color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(ThemeData theme) {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadActivations();
                  }
                : null,
          ),
          Text(
            'Page $_currentPage of $_totalPages',
            style: theme.textTheme.bodyMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadActivations();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
