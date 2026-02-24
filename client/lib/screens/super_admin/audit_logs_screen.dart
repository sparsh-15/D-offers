import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/super_admin_service.dart';
import 'package:intl/intl.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  String? _selectedAction;

  final List<String> _actions = [
    'user_activated',
    'user_deactivated',
    'user_approved',
    'user_rejected',
    'subscription_created',
    'subscription_updated',
    'subscription_cancelled',
    'shop_approved',
    'shop_rejected',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await SuperAdminService.instance.getAuditLogs(
        action: _selectedAction,
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          _logs = result['logs'] as List<dynamic>;
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
                    _selectedAction = null;
                    _currentPage = 1;
                  });
                  Navigator.pop(context);
                  _loadLogs();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedAction,
            decoration: const InputDecoration(
              labelText: 'Action Type',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Actions')),
              ..._actions.map((action) => DropdownMenuItem(
                    value: action,
                    child: Text(_formatAction(action)),
                  )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedAction = value;
              });
            },
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
                _loadLogs();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
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
          title: const Text('Audit Logs'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: _showFilters,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadLogs,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error'))
                      : _logs.isEmpty
                          ? const Center(child: Text('No logs found'))
                          : RefreshIndicator(
                              onRefresh: _loadLogs,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _logs.length,
                                itemBuilder: (context, index) {
                                  final log = _logs[index];
                                  return _buildLogCard(log, isDark, theme);
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

  Widget _buildLogCard(Map<String, dynamic> log, bool isDark, ThemeData theme) {
    final action = log['action'] as String? ?? '';
    final adminId = log['adminId'] as Map<String, dynamic>?;
    final targetUserId = log['targetUserId'] as Map<String, dynamic>?;
    final createdAt = log['createdAt'] as String?;

    DateTime? timestamp;
    if (createdAt != null) {
      try {
        timestamp = DateTime.parse(createdAt);
      } catch (e) {
        // ignore
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getActionColor(action).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getActionColor(action).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getActionIcon(action),
                  color: _getActionColor(action),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatAction(action),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (timestamp != null)
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(timestamp),
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
          const SizedBox(height: 12),
          if (adminId != null) ...[
            Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Admin: ${adminId['name'] ?? 'Unknown'} (${adminId['phone'] ?? ''})',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (targetUserId != null) ...[
            Row(
              children: [
                Icon(Icons.person_rounded, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Target: ${targetUserId['name'] ?? 'Unknown'} (${targetUserId['phone'] ?? ''})',
                  style: theme.textTheme.bodySmall,
                ),
              ],
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
                    _loadLogs();
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
                    _loadLogs();
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

  String _formatAction(String action) {
    return action
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getActionColor(String action) {
    if (action.contains('activated') || action.contains('approved')) {
      return AppColors.success;
    } else if (action.contains('deactivated') ||
        action.contains('rejected') ||
        action.contains('cancelled')) {
      return AppColors.error;
    } else if (action.contains('created')) {
      return AppColors.info;
    } else if (action.contains('updated')) {
      return AppColors.warning;
    }
    return AppColors.primary;
  }

  IconData _getActionIcon(String action) {
    if (action.contains('activated') || action.contains('approved')) {
      return Icons.check_circle_rounded;
    } else if (action.contains('deactivated') ||
        action.contains('rejected') ||
        action.contains('cancelled')) {
      return Icons.cancel_rounded;
    } else if (action.contains('created')) {
      return Icons.add_circle_rounded;
    } else if (action.contains('updated')) {
      return Icons.edit_rounded;
    }
    return Icons.info_rounded;
  }
}
