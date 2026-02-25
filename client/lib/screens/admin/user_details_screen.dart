import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../models/user_model.dart';
import '../../services/super_admin_service.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  const AdminUserDetailsScreen({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  Map<String, dynamic>? _details;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data =
          await SuperAdminService.instance.getUserDetails(widget.user.id);
      if (!mounted) return;
      setState(() {
        _details = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          leading: ThemeHelper.buildBackButton(context),
          title: const Text('User Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadDetails,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load user details',
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadDetails,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadDetails,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(theme),
                          const SizedBox(height: 16),
                          _buildProfileSection(theme),
                          const SizedBox(height: 16),
                          _buildSubscriptionSection(theme),
                          const SizedBox(height: 16),
                          _buildAuditLogsSection(theme),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Map<String, dynamic>? get _userData =>
      _details?['user'] as Map<String, dynamic>?;

  Map<String, dynamic>? get _profile =>
      _details?['profile'] as Map<String, dynamic>?;

  Map<String, dynamic>? get _subscription =>
      _details?['subscription'] as Map<String, dynamic>?;

  List<dynamic> get _recentLogs =>
      (_details?['recentLogs'] as List<dynamic>?) ?? const [];

  Widget _buildHeaderCard(ThemeData theme) {
    final user = widget.user;
    final apiUser = _userData;
    final isActive = (apiUser?['isActive'] as bool?) ?? true;
    final approvalStatus =
        (apiUser?['approvalStatus'] as String?) ?? user.approvalStatus;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isEmpty ? 'User' : user.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+91 ${user.phone}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(user.roleDisplayName),
                        avatar: const Icon(
                          Icons.person_rounded,
                          size: 16,
                        ),
                      ),
                      Chip(
                        label: Text(
                          (user.city.isNotEmpty || user.state.isNotEmpty)
                              ? '${user.city}, ${user.state}'
                              : 'Location not set',
                        ),
                        avatar: const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildStatusChip(
                        isActive ? 'ACTIVE' : 'INACTIVE',
                        isActive ? AppColors.success : AppColors.error,
                      ),
                      _buildStatusChip(
                        approvalStatus.toUpperCase(),
                        _approvalColor(approvalStatus),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  Color _approvalColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  Widget _buildProfileSection(ThemeData theme) {
    if (_profile == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.store_rounded,
                  color: ThemeHelper.getTextColor(context).withOpacity(0.7)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No shop profile available for this user.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store_rounded, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Shop Profile',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildKeyValueRow(
              theme,
              'Shop Name',
              (profile['shopName'] as String?) ?? 'N/A',
            ),
            _buildKeyValueRow(
              theme,
              'City',
              (profile['city'] as String?) ?? 'N/A',
            ),
            _buildKeyValueRow(
              theme,
              'Pincode',
              (profile['pincode'] as String?) ?? 'N/A',
            ),
            if ((profile['category'] as String? ?? '').isNotEmpty)
              _buildKeyValueRow(
                theme,
                'Category',
                profile['category'] as String,
              ),
            if ((profile['description'] as String? ?? '').isNotEmpty)
              _buildKeyValueRow(
                theme,
                'Description',
                profile['description'] as String,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection(ThemeData theme) {
    if (_subscription == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.subscriptions_rounded,
                  color: ThemeHelper.getTextColor(context).withOpacity(0.7)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No subscription found for this user.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sub = _subscription!;
    final status = (sub['status'] as String?) ?? 'inactive';
    final planSnapshot = (sub['planSnapshot'] as Map<String, dynamic>?) ?? {};

    String? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        final dt = DateTime.parse(value.toString());
        return '${dt.day.toString().padLeft(2, '0')}-'
            '${dt.month.toString().padLeft(2, '0')}-'
            '${dt.year}';
      } catch (_) {
        return value.toString();
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.subscriptions_rounded,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Subscription',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(
                  status.toUpperCase(),
                  _subscriptionStatusColor(status),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildKeyValueRow(
              theme,
              'Plan',
              (planSnapshot['displayName'] ??
                      planSnapshot['name'] ??
                      'Unknown Plan')
                  .toString(),
            ),
            _buildKeyValueRow(
              theme,
              'Price',
              planSnapshot['monthlyPrice'] != null
                  ? '₹${planSnapshot['monthlyPrice']} / month'
                  : 'N/A',
            ),
            _buildKeyValueRow(
              theme,
              'Start Date',
              parseDate(sub['startDate']) ?? 'N/A',
            ),
            _buildKeyValueRow(
              theme,
              'End Date',
              parseDate(sub['endDate']) ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Color _subscriptionStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'expired':
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Widget _buildAuditLogsSection(ThemeData theme) {
    if (_recentLogs.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.history_rounded,
                  color: ThemeHelper.getTextColor(context).withOpacity(0.7)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No recent admin activity for this user.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.info),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._recentLogs.map((log) {
              final map = log as Map<String, dynamic>;
              final admin = map['admin'] as Map<String, dynamic>?;
              final action = (map['action'] as String?) ?? '';
              final createdAt = map['createdAt']?.toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 8),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatAction(action),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (admin != null)
                            Text(
                              'By ${admin['name'] ?? 'Admin'} (${admin['role']})',
                              style: theme.textTheme.bodySmall,
                            ),
                          if (createdAt != null)
                            Text(
                              createdAt,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyValueRow(
    ThemeData theme,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAction(String action) {
    return action
        .split('_')
        .map(
          (w) =>
              w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

