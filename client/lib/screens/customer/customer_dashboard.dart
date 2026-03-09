import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import 'customer_home_tab.dart';
import 'customer_offers_tab.dart';
import 'customer_loans_tab.dart';
import 'customer_favorites_tab.dart';
import 'customer_profile_tab.dart';
import 'customer_chat_bot_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;
  final GlobalKey _favoritesKey = GlobalKey();

  void _onNavigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CustomerHomeTab(onViewAllOffers: () => _onNavigateToTab(1)),
      const CustomerOffersTab(),
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
        appBar: null,
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CustomerChatBotScreen(),
              ),
            );
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.chat_rounded, color: AppColors.white),
          tooltip: 'Help',
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              if (index == 3) {
                // Auto-refresh favorites whenever the tab is opened
                final state = _favoritesKey.currentState;
                if (state != null && state.mounted) {
                  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                  (state as dynamic).reloadFavorites();
                }
              }
              setState(() => _selectedIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_offer_rounded),
                label: 'Offers',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_rounded),
                label: 'Loans',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_rounded),
                label: 'Favorites',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
