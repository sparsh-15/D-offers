import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/offer_model.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../../services/upload_service.dart';
import '../../services/shopkeeper_ai_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';

class OfferDetailsScreen extends StatefulWidget {
  final OfferModel? offer;
  final VoidCallback? onSaved;

  const OfferDetailsScreen({
    super.key,
    this.offer,
    this.onSaved,
  });

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _termsController = TextEditingController();
  final _categoryController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _discountType = 'percentage';
  String _status = 'active';
  DateTime? _validFrom;
  DateTime? _validTo;
  List<String> _photoUrls = [];
  final List<File> _localPhotos = [];
  bool _isLoading = false;
  Map<String, dynamic>? _subscription;
  int? _currentOfferCount;
  bool _loadingSubscription = false;
  bool _loadingCategories = false;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;
  bool _isGeneratingBanner = false;
  Map<String, dynamic>? _aiWallet;
  bool _loadingAiWallet = false;
  String? _shopName;
  String? _shopLocation;

  @override
  void initState() {
    super.initState();
    if (widget.offer != null) {
      _titleController.text = widget.offer!.title;
      _descriptionController.text = widget.offer!.description;
      _termsController.text = widget.offer!.termsAndConditions;
      _categoryController.text = widget.offer!.category;
      _selectedCategory =
          widget.offer!.category.isNotEmpty ? widget.offer!.category : null;
      _discountType = widget.offer!.discountType;
      _discountValueController.text =
          widget.offer!.discountValue?.toString() ?? '';
      _status = widget.offer!.status;
      _validFrom = widget.offer!.validFrom;
      _validTo = widget.offer!.validTo;
      _photoUrls = List.from(widget.offer!.photos);
    }
    _loadSubscriptionDetails();
    _loadAiWallet();
    _loadCategories();
    _loadShopProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _termsController.dispose();
    _categoryController.dispose();
    _discountValueController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptionDetails() async {
    setState(() => _loadingSubscription = true);
    try {
      final dashboard = await AuthService.instance.getShopkeeperDashboard();
      final subscription = dashboard['subscription'] as Map<String, dynamic>?;
      int? offerCount;
      if (subscription != null &&
          (subscription['status'] == 'active' ||
              subscription['isActive'] == true)) {
        final offers = await AuthService.instance.getShopkeeperOffers();
        offerCount = offers.where((o) => o.status != 'inactive').length;
      }
      if (!mounted) return;
      setState(() {
        _subscription = subscription;
        _currentOfferCount = offerCount;
        _loadingSubscription = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSubscription = false);
    }
  }

  Future<void> _loadAiWallet() async {
    setState(() => _loadingAiWallet = true);
    try {
      final wallet = await SubscriptionService.instance.getAiWallet();
      if (!mounted) return;
      setState(() {
        _aiWallet = wallet;
        _loadingAiWallet = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAiWallet = false);
    }
  }

  Future<void> _loadShopProfile() async {
    try {
      final profile = await AuthService.instance.getShopkeeperProfile();
      if (!mounted || profile == null) return;
      setState(() {
        _shopName = profile.shopName;
        final parts = [profile.city, profile.pincode]
            .where((s) => s.isNotEmpty)
            .toList();
        _shopLocation = parts.isNotEmpty ? parts.join(', ') : null;
      });
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final response = await SubscriptionService.instance.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = response;
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return '—';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Widget _buildSubscriptionSummary(BuildContext context) {
    if (_loadingSubscription) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(),
      );
    }
    if (_subscription == null) return const SizedBox.shrink();
    final planSnapshot =
        _subscription?['planSnapshot'] as Map<String, dynamic>?;
    final planName =
        planSnapshot?['displayName'] ?? planSnapshot?['name'] ?? 'Plan';
    final status = (_subscription?['status'] ?? 'inactive').toString();
    final maxOffers = planSnapshot?['maxOffers'];
    final offerLimitLabel = maxOffers == null || maxOffers == -1
        ? 'Unlimited offers'
        : '${_currentOfferCount ?? 0} / $maxOffers offers used';
    final startDate = _formatDate(_subscription?['startDate']);
    final endDate = _formatDate(_subscription?['endDate']);
    String? aiCreditsLabel;
    if (_aiWallet != null && _aiWallet?['hasSubscription'] == true) {
      final monthlyLimit = _aiWallet?['monthlyLimit'];
      final used = (_aiWallet?['usedThisCycle'] ?? 0) as int;
      final extra = (_aiWallet?['extraCreditsCurrentCycle'] ?? 0) as int;
      final available = (_aiWallet?['availableAiCredits'] ?? 0) as int;
      if (monthlyLimit == -1) {
        aiCreditsLabel = 'AI banners: Unlimited this month';
      } else if (monthlyLimit != null) {
        aiCreditsLabel =
            'AI banners left: $available (used $used / $monthlyLimit${extra > 0 ? ' + $extra extra' : ''})';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  planName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'active'
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: status == 'active'
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            offerLimitLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Valid: $startDate → $endDate',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_loadingAiWallet) ...[
            const SizedBox(height: 6),
            const LinearProgressIndicator(minHeight: 2),
          ] else if (aiCreditsLabel != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 18, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    aiCreditsLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _addPhotoUrl() {
    final url = _photoUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a photo URL'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Basic URL validation
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL must start with http:// or https://'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _photoUrls.add(url);
      _photoUrlController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo added successfully'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _localPhotos.add(File(image.path));
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo added from gallery'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _pickMultipleFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _localPhotos.addAll(images.map((xFile) => File(xFile.path)));
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${images.length} photos added from gallery'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _localPhotos.add(File(image.path));
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo captured successfully'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Add Photos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.blue),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to capture'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.photo_library, color: AppColors.green),
                ),
                title: const Text('Pick from Gallery'),
                subtitle: const Text('Choose a single photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: AppColors.purple),
                ),
                title: const Text('Pick Multiple from Gallery'),
                subtitle: const Text('Choose multiple photos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.link, color: AppColors.orange),
                ),
                title: const Text('Add from URL'),
                subtitle: const Text('Enter photo URL manually'),
                onTap: () {
                  Navigator.pop(context);
                  // Focus will automatically go to the URL field
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPhotoPreview({String? networkUrl, File? localFile}) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: networkUrl != null
                      ? Image.network(
                          networkUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.black,
                            padding: const EdgeInsets.all(24),
                            child: const Icon(
                              Icons.broken_image,
                              color: AppColors.white,
                              size: 48,
                            ),
                          ),
                        )
                      : Image.file(
                          localFile!,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.black54,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final discountValue = _discountValueController.text.trim().isEmpty
          ? null
          : num.tryParse(_discountValueController.text.trim());

      // Upload local photos to Cloudinary first
      List<String> uploadedPhotoUrls = [];

      if (_localPhotos.isNotEmpty) {
        try {
          // Show uploading message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Uploading ${_localPhotos.length} photo(s)...'),
                duration: const Duration(seconds: 30),
              ),
            );
          }

          // Upload all local photos
          uploadedPhotoUrls =
              await UploadService.instance.uploadMultipleImages(_localPhotos);

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
        } catch (uploadError) {
          if (mounted) {
            setState(() => _isLoading = false);
            DialogHelper.showErrorSnackBar(
              context,
              'Failed to upload photos: $uploadError',
            );
          }
          return;
        }
      }

      // Combine URL photos and uploaded photo URLs
      final allPhotos = [
        ..._photoUrls,
        ...uploadedPhotoUrls,
      ];

      if (widget.offer == null) {
        final planSnapshot =
            _subscription?['planSnapshot'] as Map<String, dynamic>?;
        final maxOffers = planSnapshot?['maxOffers'];
        if (maxOffers != null &&
            maxOffers != -1 &&
            _currentOfferCount != null &&
            _currentOfferCount! >= maxOffers) {
          if (!mounted) return;
          DialogHelper.showInfoSnackBar(
            context,
            'Offer limit reached (${_currentOfferCount!}/$maxOffers). Upgrade your plan to add more.',
          );
          setState(() => _isLoading = false);
          return;
        }
        await AuthService.instance.createOffer(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          discountType: _discountType,
          discountValue: discountValue,
          validFrom: _validFrom,
          validTo: _validTo,
          photos: allPhotos,
          termsAndConditions: _termsController.text.trim(),
          category: _categoryController.text.trim(),
        );
      } else {
        await AuthService.instance.updateOffer(
          offerId: widget.offer!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          discountType: _discountType,
          discountValue: discountValue,
          validFrom: _validFrom,
          validTo: _validTo,
          status: _status,
          photos: allPhotos,
          termsAndConditions: _termsController.text.trim(),
          category: _categoryController.text.trim(),
        );
      }

      if (mounted) {
        DialogHelper.showSuccessSnackBar(
          context,
          widget.offer == null ? 'Offer created!' : 'Offer updated!',
        );
        widget.onSaved?.call();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showErrorSnackBar(context, 'Failed to save offer: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.offer == null ? 'Create Offer' : 'Edit Offer'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _save,
              tooltip: 'Save',
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSubscriptionSummary(context),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                if (_loadingCategories)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      hintText: 'Select a category',
                    ),
                    isExpanded: true,
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['value'],
                        child: Text(category['label']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _categoryController.text = value ?? '';
                      });
                    },
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _discountType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'percentage', child: Text('%')),
                          DropdownMenuItem(value: 'fixed', child: Text('Rs')),
                        ],
                        onChanged: (v) => setState(() => _discountType = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _discountValueController,
                        decoration: InputDecoration(
                          labelText: 'Value',
                          border: const OutlineInputBorder(),
                          suffixText:
                              _discountType == 'percentage' ? '%' : 'Rs',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.offer != null)
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                          value: 'inactive', child: Text('Inactive')),
                      DropdownMenuItem(value: 'expired', child: Text('Expired')),
                    ],
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                if (widget.offer != null) const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Valid From'),
                        subtitle: Text(
                            _validFrom?.toString().split(' ')[0] ?? 'Not set'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _validFrom ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) setState(() => _validFrom = date);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.grey700
                                : AppColors.grey300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        title: const Text('Valid To'),
                        subtitle: Text(
                            _validTo?.toString().split(' ')[0] ?? 'Not set'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _validTo ??
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) setState(() => _validTo = date);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.grey700
                                : AppColors.grey300,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _termsController,
                  decoration: const InputDecoration(
                    labelText: 'Terms & Conditions',
                    border: OutlineInputBorder(),
                    hintText: 'Enter any terms or conditions for this offer',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                Text(
                  'Photos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showPhotoSourceDialog,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Photos'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isGeneratingBanner
                            ? null
                            : () async {
                                if (_titleController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Add a title before generating an AI banner.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                if (_discountValueController.text
                                    .trim()
                                    .isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Add a discount value before generating an AI banner.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _isGeneratingBanner = true);
                                try {
                                  final discountValue = num.tryParse(
                                      _discountValueController.text.trim());
                                  final imageUrl = await ShopkeeperAiService
                                      .instance
                                      .generateBannerImageUrl(
                                    title: _titleController.text.trim(),
                                    description:
                                        _descriptionController.text.trim(),
                                    category: _categoryController.text.trim(),
                                    discountType: _discountType,
                                    discountValue: discountValue,
                                    shopName: _shopName,
                                    shopLocation: _shopLocation,
                                  );
                                  if (!mounted) return;
                                  setState(() {
                                    _photoUrls.insert(0, imageUrl);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('AI banner added as a photo'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e
                                            .toString()
                                            .replaceFirst('Exception: ', ''),
                                      ),
                                      duration:
                                          const Duration(seconds: 3),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(
                                        () => _isGeneratingBanner = false);
                                  }
                                }
                              },
                        icon: _isGeneratingBanner
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text('Generate AI Banner'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _photoUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Or add Photo URL',
                          border: OutlineInputBorder(),
                          hintText: 'https://example.com/image.jpg',
                        ),
                        onFieldSubmitted: (_) => _addPhotoUrl(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: _addPhotoUrl,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_photoUrls.isEmpty && _localPhotos.isEmpty)
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey800 : AppColors.grey200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.grey700 : AppColors.grey300,
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text('No photos added yet'),
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photoUrls.length + _localPhotos.length,
                      itemBuilder: (context, index) {
                        final isUrl = index < _photoUrls.length;
                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (isUrl) {
                                  _openPhotoPreview(
                                    networkUrl: _photoUrls[index],
                                  );
                                } else {
                                  _openPhotoPreview(
                                    localFile: _localPhotos[
                                        index - _photoUrls.length],
                                  );
                                }
                              },
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: AppColors.grey300,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: isUrl
                                      ? Image.network(
                                          _photoUrls[index],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image),
                                        )
                                      : Image.file(
                                          _localPhotos[
                                              index - _photoUrls.length],
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: AppColors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.black54,
                                  padding: const EdgeInsets.all(4),
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isUrl) {
                                      _photoUrls.removeAt(index);
                                    } else {
                                      _localPhotos.removeAt(
                                          index - _photoUrls.length);
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
