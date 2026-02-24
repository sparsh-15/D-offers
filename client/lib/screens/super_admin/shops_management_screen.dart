import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/super_admin_service.dart';

class ShopsManagementScreen extends StatefulWidget {
  const ShopsManagementScreen({super.key});

  @override
  State<ShopsManagementScreen> createState() => _ShopsManagementScreenState();
}

class _ShopsManagementScreenState extends State<ShopsManagementScreen> {
  List<dynamic> _shops = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  // Filters
  String? _selectedSubscriptionStatus;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await SuperAdminService.instance.getAllShops(
        subscriptionStatus: _selectedSubscriptionStatus,
        pincode: _pincodeController.text.trim().isEmpty
            ? null
            : _pincodeController.text.trim(),
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          _shops = result['shops'] as List<dynamic>;
          final pagination = result['pagination'] as Map<String, dynamic>;
          _totalPages = pagination['pages'] as int;
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

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => _buildFiltersSheet(),
    );
  }

  Widget _buildFiltersSheet() {
    final isDark = ThemeHelper.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedSubscriptionStatus = null;
                    _pincodeController.clear();
                    _currentPage = 1;
                  });
                  Navigator.pop(context);
                  _loadShops();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedSubscriptionStatus,
            decoration: const InputDecoration(
              labelText: 'Subscription Status',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              DropdownMenuItem(value: 'expired', child: Text('Expired')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSubscriptionStatus = value;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pincodeController,
            decoration: const InputDecoration(
              labelText: 'Pincode',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentPage = 1;
                });
                Navigator.pop(context);
                _loadShops();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
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
          title: const Text('Shops Management'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: _showFilters,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search shops...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadShops();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.surface : AppColors.white,
                ),
                onSubmitted: (_) => _loadShops(),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error'))
                      : _shops.isEmpty
                          ? const Center(child: Text('No shops found'))
                          : RefreshIndicator(
                              onRefresh: _loadShops,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _shops.length,
                                itemBuilder: (context, index) {
                                  final shop = _shops[index];
                                  return _buildShopCard(shop, isDark, theme);
                                },
                              ),
                            ),
            ),
            if (_totalPages > 1) _buildPagination(isDark, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(
      Map<String, dynamic> shop, bool isDark, ThemeData theme) {
    final userId = shop['userId'] as Map<String, dynamic>?;
    final subscription = shop['subscription'] as Map<String, dynamic>?;
    final subscriptionStatus = subscription?['status'] as String? ?? 'inactive';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop['shopName'] as String? ?? 'No Name',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (userId != null)
                      Text(
                        userId['phone'] as String? ?? '',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (shop['category'] != null && shop['category'] != '')
                Chip(
                  label: Text(shop['category'] as String),
                  backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                  ),
                ),
              Chip(
                label: Text(subscriptionStatus.toUpperCase()),
                backgroundColor: _getSubscriptionColor(subscriptionStatus)
                    .withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _getSubscriptionColor(subscriptionStatus),
                  fontSize: 12,
                ),
              ),
              if (userId?['pincode'] != null && userId?['pincode'] != '')
                Chip(
                  label: Text(userId?['pincode'] as String),
                  backgroundColor: AppColors.info.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: AppColors.info,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (subscription != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardBackground : AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Plan: ${subscription['planName'] ?? 'N/A'}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '₹${subscription['monthlyPrice'] ?? 0}/mo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPagination(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadShops();
                  }
                : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
          ),
          Text(
            'Page $_currentPage of $_totalPages',
            style: theme.textTheme.bodyMedium,
          ),
          TextButton.icon(
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadShops();
                  }
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }

  Color _getSubscriptionColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'inactive':
        return AppColors.warning;
      case 'expired':
        return AppColors.error;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }
}
