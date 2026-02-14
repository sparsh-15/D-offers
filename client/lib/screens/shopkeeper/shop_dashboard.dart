import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/offer_banner_preview.dart';
import '../../services/auth_service.dart';
import '../../models/offer_model.dart';
import 'shop_profile_body.dart';
import '../../widgets/offer_card.dart';

class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});

  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<_OffersManagementBodyState> _offersKey = GlobalKey();

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const ShopHomeTab(),
      OffersManagementTab(key: _offersKey),
      const LeadsTab(),
      const ShopProfileTab(),
    ]);
  }

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
              icon: Icon(Icons.local_offer_rounded),
              label: 'Offers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'Leads',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_rounded),
              label: 'Shop',
            ),
          ],
        ),
        floatingActionButton: _selectedIndex == 1
            ? FloatingActionButton.extended(
                onPressed: () {
                  _offersKey.currentState?._openEditDialog(context);
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Offer'),
              )
            : null,
      ),
    );
  }
}

class ShopHomeTab extends StatefulWidget {
  const ShopHomeTab({super.key});

  @override
  State<ShopHomeTab> createState() => _ShopHomeTabState();
}

class _ShopHomeTabState extends State<ShopHomeTab> {
  late Future<List<OfferModel>> _offersFuture;

  @override
  void initState() {
    super.initState();
    _offersFuture = AuthService.instance.getShopkeeperOffers();
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
                    'My Shop Dashboard',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Manage your business',
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
              child: FutureBuilder<List<OfferModel>>(
                future: _offersFuture,
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
                  final offers = snapshot.data ?? [];
                  final activeOffers = offers
                      .where((o) => o.status == 'active')
                      .length
                      .toString();

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
                                  'Active Offers',
                                  activeOffers,
                                  Icons.local_offer_rounded,
                                  AppColors.primaryGradient,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Total Offers',
                                  offers.length.toString(),
                                  Icons.list_alt_rounded,
                                  AppColors.accentGradient,
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
                            'Add New Offer',
                            'Create attractive offers for customers',
                            Icons.add_circle_rounded,
                            AppColors.primary,
                          ),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: _buildQuickAction(
                            context,
                            'View My Offers',
                            'Manage your existing offers',
                            Icons.local_offer_rounded,
                            AppColors.accent,
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

class OffersManagementTab extends StatelessWidget {
  const OffersManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: SafeArea(
        child: _OffersManagementBody(key: key),
      ),
    );
  }
}

class _OffersManagementBody extends StatefulWidget {
  const _OffersManagementBody({super.key});

  @override
  State<_OffersManagementBody> createState() => _OffersManagementBodyState();
}

class _OffersManagementBodyState extends State<_OffersManagementBody> {
  late Future<List<OfferModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AuthService.instance.getShopkeeperOffers();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = AuthService.instance.getShopkeeperOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('My Offers'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refresh,
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder<List<OfferModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Failed to load offers\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final offers = snapshot.data ?? [];
              if (offers.isEmpty) {
                return const Center(child: Text('No offers yet'));
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final o = offers[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * index),
                      child: OfferCard(
                        offer: o,
                        trailing: PopupMenuButton(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openEditDialog(context, offer: o);
                            } else if (value == 'delete') {
                              _deleteOffer(context, o);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
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
    );
  }

  Future<void> _showGeneratedImage(
    BuildContext context,
    GlobalKey previewKey,
    String title,
    String discountType,
    String discountValueStr,
  ) async {
    final boundary = previewKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      if (context.mounted) {
        DialogHelper.showErrorSnackBar(context, 'Preview not ready');
      }
      return;
    }
    try {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null || !context.mounted) return;
      final bytes = byteData.buffer.asUint8List();
      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Generated offer image'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.memory(bytes, fit: BoxFit.contain),
                const SizedBox(height: 8),
                Text(
                  'Use this image for your offer. You can take a screenshot to save it.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        DialogHelper.showErrorSnackBar(context, 'Could not generate image');
      }
    }
  }

  Future<void> _openEditDialog(BuildContext context,
      {OfferModel? offer}) async {
    final titleController = TextEditingController(text: offer?.title ?? '');
    final descController =
        TextEditingController(text: offer?.description ?? '');
    String discountType = offer?.discountType.isNotEmpty == true
        ? offer!.discountType
        : 'percentage';
    final discountController = TextEditingController(
      text: offer?.discountValue?.toString() ?? '',
    );
    final previewKey = GlobalKey();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(offer == null ? 'Add Offer' : 'Edit Offer'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: discountType,
                      decoration: const InputDecoration(labelText: 'Discount Type'),
                      items: const [
                        DropdownMenuItem(
                          value: 'percentage',
                          child: Text('Percentage'),
                        ),
                        DropdownMenuItem(
                          value: 'fixed',
                          child: Text('Fixed Amount'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => discountType = value);
                        }
                      },
                    ),
                    TextField(
                      controller: discountController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Discount Value'),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Offer preview',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RepaintBoundary(
                      key: previewKey,
                      child: OfferBannerPreview(
                        title: titleController.text,
                        discountType: discountType,
                        discountValue: discountController.text.isEmpty
                            ? null
                            : double.tryParse(discountController.text),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => _showGeneratedImage(
                    context,
                    previewKey,
                    titleController.text,
                    discountType,
                    discountController.text,
                  ),
                  child: const Text('Generate image'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;
    if (titleController.text.trim().isEmpty) {
      DialogHelper.showErrorSnackBar(context, 'Title is required');
      return;
    }

    try {
      if (offer == null) {
        await AuthService.instance.createOffer(
          title: titleController.text.trim(),
          description: descController.text.trim().isEmpty
              ? null
              : descController.text.trim(),
          discountType: discountType,
          discountValue: discountController.text.isEmpty
              ? null
              : double.tryParse(discountController.text) ??
                  discountController.text,
        );
        if (!mounted) return;
        DialogHelper.showSuccessSnackBar(context, 'Offer created');
      } else {
        await AuthService.instance.updateOffer(
          id: offer.id,
          title: titleController.text.trim(),
          description: descController.text.trim().isEmpty
              ? null
              : descController.text.trim(),
          discountType: discountType,
          discountValue: discountController.text.isEmpty
              ? null
              : double.tryParse(discountController.text) ??
                  discountController.text,
        );
        if (!mounted) return;
        DialogHelper.showSuccessSnackBar(context, 'Offer updated');
      }
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _deleteOffer(BuildContext context, OfferModel offer) async {
    final confirm = await DialogHelper.showConfirmDialog(
      context: context,
      title: 'Delete Offer',
      message: 'Are you sure you want to delete "${offer.title}"?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );
    if (!confirm) return;
    try {
      await AuthService.instance.deleteOffer(offer.id);
      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(context, 'Offer deleted');
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }
}

class LeadsTab extends StatelessWidget {
  const LeadsTab({super.key});

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
              title: const Text('Customer Leads'),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Customer leads will appear here',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopProfileTab extends StatelessWidget {
  const ShopProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: const SafeArea(
        child: ShopProfileBody(),
      ),
    );
  }
}
