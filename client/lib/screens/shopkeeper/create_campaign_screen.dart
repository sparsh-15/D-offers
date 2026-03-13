import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../models/campaign_model.dart';
import '../../models/offer_model.dart';
import '../../models/shopkeeper_profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/campaign_service.dart';
import '../../services/shopkeeper_ai_service.dart';
import '../../services/subscription_service.dart';
import '../../services/upload_service.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _stateController = TextEditingController();
  final _audienceSizeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 0;
  bool _loadingBootstrap = true;
  bool _estimating = false;
  bool _submitting = false;
  bool _generatingBanner = false;
  bool _uploadingBanner = false;

  List<OfferModel> _offers = const [];
  List<Map<String, dynamic>> _categories = const [];
  List<CampaignTemplateModel> _templates = const [];
  ShopkeeperProfileModel? _profile;

  bool _linkOffer = false;
  String? _selectedOfferId;
  String? _selectedCategory;
  String _gender = 'all';
  RangeValues _ageRange = const RangeValues(18, 35);
  final Set<String> _channels = {'app_inbox'};

  String _bannerMode = 'template';
  CampaignTemplateModel? _selectedTemplate;
  String? _bannerUrl;
  AudienceEstimate? _estimate;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _pincodeController.dispose();
    _stateController.dispose();
    _audienceSizeController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loadingBootstrap = true);
    try {
      final results = await Future.wait([
        AuthService.instance.getShopkeeperOffers(),
        SubscriptionService.instance.getCategories(),
        AuthService.instance.getShopkeeperProfile(),
      ]);
      _offers = results[0] as List<OfferModel>;
      _categories = results[1] as List<Map<String, dynamic>>;
      _profile = results[2] as ShopkeeperProfileModel?;
      _selectedCategory = _profile?.category.isNotEmpty == true
          ? _profile!.category
          : null;
      _cityController.text = _profile?.city ?? '';
      _pincodeController.text = _profile?.pincode ?? '';
      await _loadTemplates();
    } catch (_) {
      // Keep the wizard usable even when some bootstrap data fails.
    } finally {
      if (mounted) {
        setState(() => _loadingBootstrap = false);
      }
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await CampaignService.instance.getCampaignTemplates(
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _templates = templates;
        if (_selectedTemplate == null && templates.isNotEmpty) {
          _selectedTemplate = templates.first;
          if (_bannerMode == 'template') {
            _bannerUrl = _selectedTemplate?.bannerUrl;
          }
        }
      });
    } catch (_) {}
  }

  OfferModel? get _selectedOffer {
    if (_selectedOfferId == null) return null;
    for (final offer in _offers) {
      if (offer.id == _selectedOfferId) return offer;
    }
    return null;
  }

  Map<String, dynamic> _campaignPayload() {
    final audience = int.tryParse(_audienceSizeController.text.trim()) ??
        _estimate?.audienceCount ??
        0;
    return {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      if (_linkOffer && _selectedOfferId != null) 'offerId': _selectedOfferId,
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty)
        'shopCategory': _selectedCategory,
      'targetCity': _cityController.text.trim(),
      'targetArea': _areaController.text.trim(),
      'targetPincode': _pincodeController.text.trim(),
      'targetState': _stateController.text.trim(),
      'targetAgeMin': _ageRange.start.round(),
      'targetAgeMax': _ageRange.end.round(),
      if (_gender != 'all') 'targetGender': _gender,
      'channels': _channels.toList(),
      'selectedAudienceSize': audience,
      if (_bannerUrl != null && _bannerUrl!.isNotEmpty) 'bannerUrl': _bannerUrl,
      'bannerType': _bannerMode,
    };
  }

  double get _estimatedTotalCost {
    final estimate = _estimate;
    if (estimate == null) return 0;
    final audience = int.tryParse(_audienceSizeController.text.trim()) ??
        estimate.selectedAudienceSize;
    double total = 0;
    if (_channels.contains('app_inbox')) {
      total += audience * estimate.inboxUnitPrice;
    }
    if (_channels.contains('whatsapp')) {
      total += audience * estimate.whatsappUnitPrice;
    }
    return total;
  }

  Future<void> _estimateAudience() async {
    if (!_validateStep(0) || !_validateStep(1)) {
      return;
    }
    setState(() => _estimating = true);
    try {
      final estimate = await CampaignService.instance.estimateAudience(
        _campaignPayload(),
      );
      if (!mounted) return;
      setState(() {
        _estimate = estimate;
        _audienceSizeController.text =
            estimate.selectedAudienceSize.toString();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _estimating = false);
      }
    }
  }

  bool _validateStep(int step, {bool silent = false}) {
    String? error;
    switch (step) {
      case 0:
        if (_titleController.text.trim().isEmpty) {
          error = 'Campaign title is required.';
        } else if (_selectedCategory == null || _selectedCategory!.isEmpty) {
          error = 'Select a business category.';
        }
        break;
      case 1:
        if (_cityController.text.trim().isEmpty &&
            _pincodeController.text.trim().isEmpty &&
            _stateController.text.trim().isEmpty) {
          error = 'Add at least one location filter.';
        }
        break;
      case 2:
        if (_channels.isEmpty) {
          error = 'Select at least one delivery channel.';
        } else if (_estimate == null) {
          error = 'Estimate the audience before continuing.';
        }
        break;
      case 3:
        if (_bannerUrl == null || _bannerUrl!.isEmpty) {
          error = 'Select, upload, or generate a banner.';
        }
        break;
      default:
        break;
    }

    if (!silent && error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
    return error == null;
  }

  void _onOfferSelection(String? offerId) {
    setState(() {
      _selectedOfferId = offerId;
    });
    final offer = _selectedOffer;
    if (offer == null) return;
    if (_titleController.text.trim().isEmpty) {
      _titleController.text = offer.title;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _descriptionController.text = offer.description;
    }
    if ((_selectedCategory == null || _selectedCategory!.isEmpty) &&
        offer.category.isNotEmpty) {
      _selectedCategory = offer.category;
      _loadTemplates();
    }
  }

  Future<void> _generateAiBanner() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the campaign title before AI generation.')),
      );
      return;
    }
    setState(() => _generatingBanner = true);
    try {
      final offer = _selectedOffer;
      final bannerUrl = await ShopkeeperAiService.instance.generateBannerImageUrl(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        discountType: offer?.discountType,
        discountValue: offer?.discountValue is num ? offer?.discountValue as num : null,
        shopName: _profile?.shopName,
        shopLocation: [
          if ((_profile?.city ?? '').isNotEmpty) _profile?.city,
          if ((_profile?.pincode ?? '').isNotEmpty) _profile?.pincode,
        ].whereType<String>().join(', '),
      );
      if (!mounted) return;
      setState(() {
        _bannerMode = 'ai_generated';
        _bannerUrl = bannerUrl;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _generatingBanner = false);
      }
    }
  }

  Future<void> _pickAndUploadBanner() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => _uploadingBanner = true);
    try {
      final url = await UploadService.instance.uploadImage(File(image.path));
      if (!mounted) return;
      setState(() {
        _bannerMode = 'custom_upload';
        _bannerUrl = url;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingBanner = false);
      }
    }
  }

  Future<void> _createCampaign() async {
    for (var step = 0; step <= 3; step += 1) {
      if (!_validateStep(step)) {
        setState(() => _currentStep = step);
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final campaign = await CampaignService.instance.createCampaign(_campaignPayload());
      if (!mounted) return;
      Navigator.of(context).pop(campaign);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingBootstrap) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New Campaign')),
      body: Stepper(
        currentStep: _currentStep,
        type: StepperType.vertical,
        onStepTapped: (step) => setState(() => _currentStep = step),
        onStepContinue: () {
          if (_currentStep == 4) {
            _createCampaign();
            return;
          }
          if (_validateStep(_currentStep)) {
            setState(() => _currentStep += 1);
          }
        },
        onStepCancel: () {
          if (_currentStep == 0) {
            Navigator.of(context).maybePop();
            return;
          }
          setState(() => _currentStep -= 1);
        },
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 4;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton(
                  onPressed: (_submitting || _estimating) ? null : details.onStepContinue,
                  child: Text(isLast ? 'Create Draft' : 'Continue'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: (_submitting || _estimating) ? null : details.onStepCancel,
                  child: Text(_currentStep == 0 ? 'Close' : 'Back'),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Basics'),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Campaign title'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: _linkOffer,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Link to an existing offer'),
                  subtitle: const Text('Optional. Reuse offer copy and connect analytics to that offer.'),
                  onChanged: (value) {
                    setState(() {
                      _linkOffer = value;
                      if (!value) {
                        _selectedOfferId = null;
                      }
                    });
                  },
                ),
                if (_linkOffer)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOfferId,
                    decoration: const InputDecoration(labelText: 'Select offer'),
                    items: _offers
                        .map(
                          (offer) => DropdownMenuItem(
                            value: offer.id,
                            child: Text(offer.title),
                          ),
                        )
                        .toList(),
                    onChanged: _onOfferSelection,
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Business category'),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category['slug']?.toString() ?? category['name']?.toString() ?? category['value']?.toString() ?? '',
                          child: Text(category['label']?.toString() ?? category['name']?.toString() ?? category['value']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _selectedTemplate = null;
                      if (_bannerMode == 'template') {
                        _bannerUrl = null;
                      }
                    });
                    _loadTemplates();
                  },
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Audience'),
            isActive: _currentStep >= 1,
            content: Column(
              children: [
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaController,
                  decoration: const InputDecoration(labelText: 'Area'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pincodeController,
                  decoration: const InputDecoration(labelText: 'Pincode'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(labelText: 'State'),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Age ${_ageRange.start.round()} - ${_ageRange.end.round()}',
                  ),
                ),
                RangeSlider(
                  values: _ageRange,
                  min: 18,
                  max: 65,
                  divisions: 47,
                  labels: RangeLabels(
                    _ageRange.start.round().toString(),
                    _ageRange.end.round().toString(),
                  ),
                  onChanged: (value) => setState(() => _ageRange = value),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _gender = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _estimating ? null : _estimateAudience,
                  icon: _estimating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.groups_rounded),
                  label: const Text('Estimate audience'),
                ),
                if (_estimate != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderMid),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '~${_estimate!.audienceCount} customers match your criteria',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'App inbox: Rs ${_estimate!.inboxUnitPrice.toStringAsFixed(2)} per message',
                        ),
                        Text(
                          'WhatsApp: Rs ${_estimate!.whatsappUnitPrice.toStringAsFixed(2)} per message',
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Step(
            title: const Text('Channels & Budget'),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _channels.contains('app_inbox'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _channels.add('app_inbox');
                      } else {
                        _channels.remove('app_inbox');
                      }
                    });
                  },
                  title: const Text('App Inbox Notification'),
                  subtitle: Text(
                    _estimate == null
                        ? 'Estimate audience to get pricing'
                        : 'Rs ${_estimate!.inboxUnitPrice.toStringAsFixed(2)} per message',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _channels.contains('whatsapp'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _channels.add('whatsapp');
                      } else {
                        _channels.remove('whatsapp');
                      }
                    });
                  },
                  title: const Text('WhatsApp Broadcast'),
                  subtitle: Text(
                    _estimate == null
                        ? 'Estimate audience to get pricing'
                        : 'Rs ${_estimate!.whatsappUnitPrice.toStringAsFixed(2)} per message',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _audienceSizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Audience size to target'),
                ),
                if (_estimate != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Estimated total: Rs ${_estimatedTotalCost.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Step(
            title: const Text('Banner'),
            isActive: _currentStep >= 3,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'template', label: Text('Template')),
                    ButtonSegment(value: 'ai_generated', label: Text('AI')),
                    ButtonSegment(value: 'custom_upload', label: Text('Upload')),
                  ],
                  selected: {_bannerMode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _bannerMode = selection.first;
                      if (_bannerMode == 'template') {
                        _bannerUrl = _selectedTemplate?.bannerUrl;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_bannerMode == 'template') ...[
                  if (_templates.isEmpty)
                    const Text('No templates available for this category yet.'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _templates.map((template) {
                      final isSelected = _selectedTemplate?.id == template.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTemplate = template;
                            _bannerUrl = template.bannerUrl;
                          });
                        },
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.accent : AppColors.borderMid,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 1.9,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    template.bannerUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppColors.surface,
                                      child: const Icon(Icons.image_not_supported_rounded),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(template.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (_bannerMode == 'ai_generated')
                  FilledButton.icon(
                    onPressed: _generatingBanner ? null : _generateAiBanner,
                    icon: _generatingBanner
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Generate AI banner'),
                  ),
                if (_bannerMode == 'custom_upload')
                  FilledButton.icon(
                    onPressed: _uploadingBanner ? null : _pickAndUploadBanner,
                    icon: _uploadingBanner
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_rounded),
                    label: const Text('Upload custom banner'),
                  ),
                const SizedBox(height: 16),
                if (_bannerUrl != null && _bannerUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _bannerUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: AppColors.surface,
                        alignment: Alignment.center,
                        child: const Text('Banner preview unavailable'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 4,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewTile(label: 'Title', value: _titleController.text.trim()),
                _ReviewTile(label: 'Category', value: _selectedCategory ?? '-'),
                _ReviewTile(
                  label: 'Target area',
                  value: [
                    _cityController.text.trim(),
                    _areaController.text.trim(),
                    _pincodeController.text.trim(),
                  ].where((part) => part.isNotEmpty).join(', '),
                ),
                _ReviewTile(label: 'Channels', value: _channels.join(', ')),
                _ReviewTile(
                  label: 'Estimated audience',
                  value: _estimate?.audienceCount.toString() ?? 'Not estimated',
                ),
                _ReviewTile(
                  label: 'Selected audience',
                  value: _audienceSizeController.text.trim().isEmpty
                      ? '-'
                      : _audienceSizeController.text.trim(),
                ),
                _ReviewTile(
                  label: 'Estimated total',
                  value: 'Rs ${_estimatedTotalCost.toStringAsFixed(2)}',
                ),
                if (_bannerUrl != null && _bannerUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _bannerUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
