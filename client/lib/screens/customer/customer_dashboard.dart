import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import 'customer_home_tab.dart';
import 'customer_offers_tab.dart';
import 'customer_claims_tab.dart';
import 'customer_loans_tab.dart';
import 'customer_favorites_tab.dart';
import 'customer_profile_tab.dart';
import 'customer_chat_bot_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;
  final GlobalKey _favoritesKey = GlobalKey();

  static const List<_CustomerNavItem> _navItems = [
    _CustomerNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _CustomerNavItem(
      label: 'Offers',
      icon: Icons.local_offer_outlined,
      activeIcon: Icons.local_offer_rounded,
    ),
    _CustomerNavItem(
      label: 'Claims',
      icon: Icons.grid_view_rounded,
      activeIcon: Icons.grid_view_rounded,
    ),
    _CustomerNavItem(
      label: 'Loans',
      icon: Icons.account_balance_outlined,
      activeIcon: Icons.account_balance_rounded,
    ),
    _CustomerNavItem(
      label: 'Picks',
      icon: Icons.favorite_border_rounded,
      activeIcon: Icons.favorite_rounded,
    ),
    _CustomerNavItem(
      label: 'Me',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  void _onNavigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleTabTap(int index) {
    if (index == 4) {
      // Auto-refresh favorites whenever the tab is opened.
      final state = _favoritesKey.currentState;
      if (state != null && state.mounted) {
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        (state as dynamic).reloadFavorites();
      }
    }
    setState(() => _selectedIndex = index);
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex < 0
        ? 0
        : (widget.initialTabIndex > 5 ? 5 : widget.initialTabIndex);
    _screens = [
      CustomerHomeTab(onViewAllOffers: () => _onNavigateToTab(1)),
      const CustomerOffersTab(),
      const CustomerClaimsTab(),
      const CustomerLoansTab(),
      CustomerFavoritesTab(
        key: _favoritesKey,
        onBrowseOffers: () => _onNavigateToTab(1),
      ),
      const CustomerProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await DialogHelper.showExitDialog(context);
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F8),
        appBar: null,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF7F8FB),
                Color(0xFFF1F3F7),
              ],
            ),
          ),
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ),
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CustomerChatBotScreen(),
                    ),
                  );
                },
                elevation: 4,
                backgroundColor: const Color(0xFF1E2536),
                child: const Icon(Icons.chat_bubble_rounded,
                    color: AppColors.white),
                tooltip: 'Help',
              )
            : null,
        bottomNavigationBar: _buildBottomDock(),
      ),
    );
  }

  Widget _buildBottomDock() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 82,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE3E6EE)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF111827).withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < _navItems.length; i++)
                Expanded(
                  child: _buildDockNavItem(i, _navItems[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockNavItem(int index, _CustomerNavItem item) {
    final isActive = _selectedIndex == index;
    final iconColor =
        isActive ? const Color(0xFFF8991D) : const Color(0xFF7C8498);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _handleTabTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                color: iconColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _CustomerNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
