import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedReportType = 'users';

  final List<Map<String, dynamic>> _reportTypes = [
    {
      'id': 'users',
      'title': 'User Report',
      'description': 'Detailed user registration and activity report',
      'icon': Icons.people_rounded,
      'color': AppColors.primary,
    },
    {
      'id': 'shopkeepers',
      'title': 'Shopkeeper Report',
      'description': 'Shopkeeper onboarding and approval statistics',
      'icon': Icons.store_rounded,
      'color': AppColors.accent,
    },
    {
      'id': 'offers',
      'title': 'Offers Report',
      'description': 'Offer creation, views, and redemption analytics',
      'icon': Icons.local_offer_rounded,
      'color': AppColors.success,
    },
    {
      'id': 'subscriptions',
      'title': 'Subscription Report',
      'description': 'Subscription plans, revenue, and renewals',
      'icon': Icons.subscriptions_rounded,
      'color': const Color(0xFF667EEA),
    },
    {
      'id': 'coupons',
      'title': 'Coupon Report',
      'description': 'Coupon usage and discount distribution',
      'icon': Icons.confirmation_number_rounded,
      'color': const Color(0xFF764BA2),
    },
    {
      'id': 'agents',
      'title': 'Agent Performance Report',
      'description': 'SSA and sales agent performance metrics',
      'icon': Icons.support_agent_rounded,
      'color': AppColors.warning,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration:
            BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateRangeSelector(),
              const SizedBox(height: 20),
              const Text(
                'Select Report Type',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._reportTypes.asMap().entries.map((entry) {
                final index = entry.key;
                final report = entry.value;
                return FadeInUp(
                  delay: Duration(milliseconds: 100 * index),
                  child: _buildReportCard(report),
                );
              }),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateReport,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Generate Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(
                      _startDate != null && _endDate != null
                          ? '${DateFormat('MMM d, y').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}'
                          : 'Select Date Range',
                    ),
                  ),
                ),
                if (_startDate != null && _endDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildQuickDateChip('Today', () {
                  setState(() {
                    _startDate = DateTime.now();
                    _endDate = DateTime.now();
                  });
                }),
                _buildQuickDateChip('Last 7 Days', () {
                  setState(() {
                    _endDate = DateTime.now();
                    _startDate = _endDate!.subtract(const Duration(days: 7));
                  });
                }),
                _buildQuickDateChip('Last 30 Days', () {
                  setState(() {
                    _endDate = DateTime.now();
                    _startDate = _endDate!.subtract(const Duration(days: 30));
                  });
                }),
                _buildQuickDateChip('This Month', () {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = DateTime(now.year, now.month, 1);
                    _endDate = DateTime(now.year, now.month + 1, 0);
                  });
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: AppColors.primary),
    );
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
    }
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final isSelected = _selectedReportType == report['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? report['color'] : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _selectedReportType = report['id'];
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (report['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  report['icon'],
                  color: report['color'],
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: report['color'],
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateReport() {
    if (_startDate == null || _endDate == null) {
      DialogHelper.showErrorSnackBar(
        context,
        'Please select a date range',
      );
      return;
    }

    final reportType = _reportTypes.firstWhere(
      (r) => r['id'] == _selectedReportType,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(reportType['icon'], color: reportType['color']),
            const SizedBox(width: 12),
            Expanded(child: Text(reportType['title'])),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date Range:'),
            Text(
              '${DateFormat('MMM d, y').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Report generation is in progress...'),
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    // Simulate report generation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        DialogHelper.showSuccessSnackBar(
          context,
          'Report generated successfully! Check your downloads.',
        );
      }
    });
  }
}
