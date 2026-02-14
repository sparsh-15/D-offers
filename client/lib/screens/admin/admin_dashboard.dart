import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/theme_toggle.dart';
import '../../widgets/profile_option_tile.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../models/user_model.dart';
import '../../models/role_enum.dart';
import '../role_selection/role_selection_screen.dart';
import '../common/edit_profile_page.dart';
import '../common/security_page.dart';
import '../common/settings_page.dart';
import '../common/help_support_page.dart';
import '../common/about_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminHomeTab(),
    const UsersManagementTab(),
    const ShopkeepersApprovalTab(),
    const AdminProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await DialogHelper.showExitDialog(context);
        return shouldExit;
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.approval_rounded),
              label: 'Approvals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_rounded),
              label: 'Admin',
            ),
          ],
        ),
      ),
    );
  }
}

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = AuthService.instance.getAdminStats();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Platform Overview',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_rounded),
                  onPressed: () {},
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Failed to load stats\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final stats = snapshot.data ?? {};
                  final totalUsers = stats['totalUsers']?.toString() ?? '0';
                  final totalShopkeepers =
                      stats['totalShopkeepers']?.toString() ?? '0';
                  final activeOffers = stats['activeOffers']?.toString() ?? '0';
                  final pendingShopkeepers =
                      stats['pendingShopkeepers']?.toString() ?? '0';

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Total Users',
                                  totalUsers,
                                  Icons.people_rounded,
                                  AppColors.primaryGradient,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Shopkeepers',
                                  totalShopkeepers,
                                  Icons.store_rounded,
                                  AppColors.accentGradient,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeInUp(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Active Offers',
                                  activeOffers,
                                  Icons.local_offer_rounded,
                                  const LinearGradient(
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Pending',
                                  pendingShopkeepers,
                                  Icons.pending_rounded,
                                  const LinearGradient(
                                    colors: [
                                      Color(0xFFF093FB),
                                      Color(0xFFF5576C)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeInLeft(
                          child: Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          child: _buildQuickAction(
                            context,
                            AppStrings.manageUsers,
                            'View and manage all users',
                            Icons.people_rounded,
                            AppColors.primary,
                          ),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: _buildQuickAction(
                            context,
                            AppStrings.approveShopkeepers,
                            'Review pending shopkeeper requests',
                            Icons.approval_rounded,
                            AppColors.accent,
                          ),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: _buildQuickAction(
                            context,
                            AppStrings.platformAnalytics,
                            'View detailed platform statistics',
                            Icons.analytics_rounded,
                            AppColors.success,
                          ),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          child: _buildQuickAction(
                            context,
                            AppStrings.reports,
                            'Generate and view reports',
                            Icons.assessment_rounded,
                            AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Gradient gradient,
  ) {
    return GradientCard(
      gradient: gradient,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {},
      ),
    );
  }
}

class UsersManagementTab extends StatefulWidget {
  const UsersManagementTab({super.key});

  @override
  State<UsersManagementTab> createState() => _UsersManagementTabState();
}

class _UsersManagementTabState extends State<UsersManagementTab> {
  late Future<List<UserModel>> _future;
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _future = AuthService.instance.getUsers(limit: 50);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = AuthService.instance.getUsers(limit: 50);
    });
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    return users.where((user) {
      final matchesRole = _selectedRole == 'all' ||
          user.role.toString().split('.').last == _selectedRole;
      final matchesSearch = _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery) ||
          user.phone.contains(_searchQuery) ||
          (user.city.isNotEmpty &&
              user.city.toLowerCase().contains(_searchQuery));
      return matchesRole && matchesSearch;
    }).toList();
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.error;
      case UserRole.shopkeeper:
        return AppColors.accent;
      case UserRole.customer:
        return AppColors.primary;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.shopkeeper:
        return Icons.store_rounded;
      case UserRole.customer:
        return Icons.person_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Users',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'View and manage all platform users',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _refresh,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: ThemeHelper.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name, phone, or city...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Role Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All Users', Icons.people_rounded),
                        const SizedBox(width: 8),
                        _buildFilterChip('customer', 'Customers', Icons.person_rounded),
                        const SizedBox(width: 8),
                        _buildFilterChip('shopkeeper', 'Shopkeepers', Icons.store_rounded),
                        const SizedBox(width: 8),
                        _buildFilterChip('admin', 'Admins', Icons.admin_panel_settings_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
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
                              'Failed to load users',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final allUsers = snapshot.data ?? [];
                  final filteredUsers = _filterUsers(allUsers);

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.people_outline_rounded,
                              size: 64,
                              color: ThemeHelper.getTextColor(context)
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No users found'
                                  : 'No users available',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try adjusting your search or filters'
                                  : 'Users will appear here once registered',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return FadeInUp(
                          delay: Duration(milliseconds: 50 * index),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                // TODO: Navigate to user details
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(user.role)
                                            .withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getRoleIcon(user.role),
                                        color: _getRoleColor(user.role),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // User Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  user.name.isEmpty
                                                      ? 'User'
                                                      : user.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // Status Badge
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                          user.approvalStatus)
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  user.approvalStatus
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    color: _getStatusColor(
                                                        user.approvalStatus),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.phone_rounded,
                                                size: 14,
                                                color: ThemeHelper.getTextColor(
                                                        context)
                                                    .withOpacity(0.6),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '+91 ${user.phone}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                          if (user.city.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_rounded,
                                                  size: 14,
                                                  color: ThemeHelper.getTextColor(
                                                          context)
                                                      .withOpacity(0.6),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    '${user.city}, ${user.state}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          // Role Badge
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getRoleColor(user.role)
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getRoleIcon(user.role),
                                                  size: 14,
                                                  color:
                                                      _getRoleColor(user.role),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  user.role
                                                      .toString()
                                                      .split('.')
                                                      .last
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    color:
                                                        _getRoleColor(user.role),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Actions Menu
                                    PopupMenuButton(
                                      icon: Icon(
                                        Icons.more_vert_rounded,
                                        color: ThemeHelper.getTextColor(context)
                                            .withOpacity(0.6),
                                      ),
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'view',
                                          child: Row(
                                            children: [
                                              Icon(Icons.visibility_rounded,
                                                  size: 20),
                                              SizedBox(width: 8),
                                              Text('View Details'),
                                            ],
                                          ),
                                        ),
                                        if (user.role != UserRole.admin)
                                          const PopupMenuItem(
                                            value: 'suspend',
                                            child: Row(
                                              children: [
                                                Icon(Icons.block_rounded,
                                                    size: 20),
                                                SizedBox(width: 8),
                                                Text('Suspend'),
                                              ],
                                            ),
                                          ),
                                        if (user.role != UserRole.admin)
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_rounded,
                                                    size: 20,
                                                    color: AppColors.error),
                                                SizedBox(width: 8),
                                                Text('Delete',
                                                    style: TextStyle(
                                                        color:
                                                            AppColors.error)),
                                              ],
                                            ),
                                          ),
                                      ],
                                      onSelected: (value) {
                                        // TODO: Handle actions
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedRole == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedRole = value;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class ShopkeepersApprovalTab extends StatelessWidget {
  const ShopkeepersApprovalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: SafeArea(
        child: _ShopkeepersApprovalBody(),
      ),
    );
  }
}

class _ShopkeepersApprovalBody extends StatefulWidget {
  @override
  State<_ShopkeepersApprovalBody> createState() =>
      _ShopkeepersApprovalBodyState();
}

class _ShopkeepersApprovalBodyState extends State<_ShopkeepersApprovalBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<UserModel>> _pendingFuture;
  late Future<List<UserModel>> _approvedFuture;
  late Future<List<UserModel>> _rejectedFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    _pendingFuture = AuthService.instance.getShopkeepers(status: 'pending');
    _approvedFuture = AuthService.instance.getShopkeepers(status: 'approved');
    _rejectedFuture = AuthService.instance.getShopkeepers(status: 'rejected');
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 0.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Shopkeeper Approvals',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review and manage shopkeeper requests',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _refresh,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
        ),
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: ThemeHelper.getTextColor(context).withOpacity(0.6),
          tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pending_rounded, size: 18),
                    const SizedBox(width: 6),
                    FutureBuilder<List<UserModel>>(
                      future: _pendingFuture,
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return Badge(
                          label: Text('$count'),
                          isLabelVisible: count > 0,
                          child: const Text('Pending'),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 18),
                    const SizedBox(width: 6),
                    const Text('Approved'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cancel_rounded, size: 18),
                    const SizedBox(width: 6),
                    const Text('Rejected'),
                  ],
                ),
              ),
            ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
                _buildShopkeeperList(_pendingFuture, 0),
                _buildShopkeeperList(_approvedFuture, 1),
                _buildShopkeeperList(_rejectedFuture, 2),
              ],
          ),
        ),
        ],
    );
  }

  Widget _buildShopkeeperList(Future<List<UserModel>> future, int tabIndex) {
    return FutureBuilder<List<UserModel>>(
      key: ValueKey('shopkeeper_list_$tabIndex'),
      future: future,
      builder: (context, snapshot) {
        // Show loading indicator while waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        // Show error state if there's an error
        if (snapshot.hasError) {
          return Center(
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
                    'Failed to load shopkeepers',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Get items, default to empty list if null
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          final emptyMessages = {
            0: ('No Pending Requests', 'All shopkeeper requests have been reviewed', Icons.check_circle_outline_rounded),
            1: ('No Approved Shopkeepers', 'Approved shopkeepers will appear here', Icons.store_outlined),
            2: ('No Rejected Requests', 'Rejected requests will appear here', Icons.cancel_outlined),
          };
          final (title, message, icon) = emptyMessages[tabIndex]!;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 64,
                    color: ThemeHelper.getTextColor(context).withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final shopkeeper = items[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * index),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row
                              Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.accentGradient,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.store_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shopkeeper.name.isEmpty
                                              ? 'Shopkeeper'
                                              : shopkeeper.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone_rounded,
                                              size: 16,
                                              color: ThemeHelper.getTextColor(
                                                      context)
                                                  .withOpacity(0.6),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '+91 ${shopkeeper.phone}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                              shopkeeper.approvalStatus)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      shopkeeper.approvalStatus.toUpperCase(),
                                      style: TextStyle(
                                        color: _getStatusColor(
                                            shopkeeper.approvalStatus),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Location Info
                              if (shopkeeper.city.isNotEmpty ||
                                  shopkeeper.pincode.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: ThemeHelper.getSurfaceColor(context),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 20,
                                        color: AppColors.accent,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (shopkeeper.city.isNotEmpty)
                                              Text(
                                                '${shopkeeper.city}, ${shopkeeper.state}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            if (shopkeeper.pincode.isNotEmpty)
                                              Text(
                                                'PIN: ${shopkeeper.pincode}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Action Buttons (only for pending)
                              if (tabIndex == 0) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _approve(
                                            context,
                                            shopkeeper.id,
                                            shopkeeper.name.isEmpty
                                                ? 'Shopkeeper'
                                                : shopkeeper.name),
                                        icon: const Icon(
                                          Icons.check_rounded,
                                          size: 20,
                                        ),
                                        label: const Text(
                                          'Approve',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _reject(
                                            context,
                                            shopkeeper.id,
                                            shopkeeper.name.isEmpty
                                                ? 'Shopkeeper'
                                                : shopkeeper.name),
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 20,
                                        ),
                                        label: const Text(
                                          'Reject',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(
                                            color: AppColors.error,
                                            width: 2,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _approve(
      BuildContext context, String id, String displayName) async {
    try {
      await AuthService.instance.approveShopkeeper(id);
      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(
          context, 'Approved $displayName successfully');
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _reject(
      BuildContext context, String id, String displayName) async {
    final confirm = await DialogHelper.showConfirmDialog(
      context: context,
      title: 'Reject Shopkeeper',
      message: 'Are you sure you want to reject $displayName?',
      confirmText: 'Reject',
      cancelText: 'Cancel',
      isDestructive: true,
    );
    if (!confirm) return;
    try {
      await AuthService.instance.rejectShopkeeper(id);
      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(
          context, 'Rejected $displayName successfully');
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }
}

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  late Future<UserModel> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = AuthService.instance.fetchCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: SafeArea(
        child: FutureBuilder<UserModel>(
          future: _userFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final displayName = user?.name.isEmpty == true || user == null
                ? 'Admin User'
                : user.name;
            final displayPhone = user?.phone ?? '';

            return Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  title: const Text('Admin Profile'),
                  actions: const [
                    ThemeToggleButton(),
                  ],
                ),
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.admin_panel_settings_rounded,
                      size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const CircularProgressIndicator()
                else ...[
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (displayPhone.isNotEmpty)
                    Text(
                      '+91 $displayPhone',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    children: [
                      const ThemeToggle(),
                      ProfileOptionTile(
                        icon: Icons.edit_rounded,
                        title: 'Edit Profile',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditProfilePage(
                                user: user,
                                onSaved: () {
                                  setState(() {
                                    _userFuture = AuthService.instance.fetchCurrentUser();
                                  });
                                },
                              ),
                            ),
                          );
                          if (mounted) {
                            setState(() {
                              _userFuture = AuthService.instance.fetchCurrentUser();
                            });
                          }
                        },
                      ),
                      ProfileOptionTile(
                        icon: Icons.security_rounded,
                        title: 'Security',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SecurityPage(),
                            ),
                          );
                        },
                      ),
                      ProfileOptionTile(
                        icon: Icons.settings_rounded,
                        title: 'Settings',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                      ProfileOptionTile(
                        icon: Icons.help_rounded,
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HelpSupportPage(),
                            ),
                          );
                        },
                      ),
                      ProfileOptionTile(
                        icon: Icons.info_rounded,
                        title: 'About',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AboutPage(),
                            ),
                          );
                        },
                      ),
                      ProfileOptionTile(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        isDestructive: true,
                        onTap: () async {
                          final shouldLogout = await DialogHelper.showLogoutDialog(context);
                          if (shouldLogout && context.mounted) {
                            AuthStore.clear();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                              (route) => false,
                            );
                            DialogHelper.showSuccessSnackBar(
                                context, 'Logged out successfully');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
