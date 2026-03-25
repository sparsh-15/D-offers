import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/reward_action_mixin.dart';
import '../../models/campaign_model.dart';
import '../../models/offer_model.dart';
import '../../models/shopkeeper_profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/campaign_service.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen>
    with RewardActionMixin<CreateCampaignScreen> {
  final _pincodeController = TextEditingController();
  final _targetAudienceSizeController = TextEditingController();
  final _estimatedAudienceSizeController = TextEditingController();

  int _currentStep = 0;
  bool _loadingBootstrap = true;
  bool _estimating = false;
  bool _submitting = false;

  List<OfferModel> _offers = const [];
  ShopkeeperProfileModel? _profile;

  String? _selectedOfferId;
  String? _selectedBannerUrl;
  String? _selectedState;
  String? _selectedCity;

  List<String> _states = const [];
  List<String> _cities = const [];
  bool _loadingStates = false;
  bool _loadingCities = false;
  final Set<String> _failedBannerUrls = <String>{};

  String _targetMode = 'pincode';
  DateTime? _scheduledAt;

  String _gender = 'all';
  RangeValues _ageRange = const RangeValues(18, 35);
  final Set<String> _channels = {'app_inbox'};
  AudienceEstimate? _estimate;

  static const List<_ChannelOption> _channelOptions = [
    _ChannelOption(
      key: 'app_inbox',
      label: 'App Notification',
      enabled: true,
      subtitle: 'Delivered inside the MyOffers app inbox.',
    ),
    _ChannelOption(
      key: 'whatsapp',
      label: 'WhatsApp',
      enabled: false,
      subtitle: 'Coming soon: provider not integrated yet.',
    ),
    _ChannelOption(
      key: 'email',
      label: 'Email Text',
      enabled: false,
      subtitle: 'Coming soon: provider not integrated yet.',
    ),
    _ChannelOption(
      key: 'push_notification',
      label: 'Push Notification',
      enabled: false,
      subtitle: 'Coming soon: device-token push pipeline pending.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    _targetAudienceSizeController.dispose();
    _estimatedAudienceSizeController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loadingBootstrap = true);
    try {
      final results = await Future.wait([
        AuthService.instance.getShopkeeperOffers(),
        AuthService.instance.getShopkeeperProfile(),
      ]);
      _offers = results[0] as List<OfferModel>;
      _profile = results[1] as ShopkeeperProfileModel?;
      _pincodeController.text = _profile?.pincode ?? '';
      await _loadStates();
    } catch (_) {
      // Keep the wizard usable even when some bootstrap data fails.
    } finally {
      if (mounted) {
        setState(() => _loadingBootstrap = false);
      }
    }
  }

  Future<void> _loadStates() async {
    setState(() => _loadingStates = true);
    try {
      final states = await AuthService.instance.getTargetStates();
      if (!mounted) return;
      setState(() {
        _states = states;
        if (_selectedState != null && !_states.contains(_selectedState)) {
          _selectedState = null;
          _selectedCity = null;
          _cities = const [];
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _states = const []);
    } finally {
      if (mounted) {
        setState(() => _loadingStates = false);
      }
    }
  }

  Future<void> _onStateSelected(String? state) async {
    setState(() {
      _selectedState = state;
      _selectedCity = null;
      _cities = const [];
    });
    if (state == null || state.trim().isEmpty) return;

    setState(() => _loadingCities = true);
    try {
      final cities = await AuthService.instance.getTargetCitiesByState(state);
      if (!mounted) return;
      setState(() {
        _cities = cities;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cities = const []);
    } finally {
      if (mounted) {
        setState(() => _loadingCities = false);
      }
    }
  }

  OfferModel? get _selectedOffer {
    if (_selectedOfferId == null) return null;
    for (final offer in _offers) {
      if (offer.id == _selectedOfferId) return offer;
    }
    return null;
  }

  Map<String, dynamic> _campaignPayload() {
    final offer = _selectedOffer;
    final audience = int.tryParse(_targetAudienceSizeController.text.trim()) ??
        _estimate?.audienceCount ??
        0;

    final payload = <String, dynamic>{
      'title': offer?.title ?? 'Campaign',
      'description': offer?.description ?? '',
      if (offer?.id != null) 'offerId': offer!.id,
      if (offer != null && offer.category.isNotEmpty)
        'shopCategory': offer.category,
      'targetAgeMin': _ageRange.start.round(),
      'targetAgeMax': _ageRange.end.round(),
      if (_gender != 'all') 'targetGender': _gender,
      'channels': _channels.toList(),
      'selectedAudienceSize': audience,
      if (_selectedBannerUrl != null && _selectedBannerUrl!.isNotEmpty)
        'bannerUrl': _selectedBannerUrl,
      'bannerType': 'offer_banner',
      'scheduledAt': _scheduledAt?.toIso8601String(),
      'isPanIndia': _targetMode == 'pan_india',
    };

    if (_targetMode == 'pincode') {
      payload['targetPincode'] = _pincodeController.text.trim();
    }
    if (_targetMode == 'state') {
      payload['targetState'] = (_selectedState ?? '').trim();
    }
    if (_targetMode == 'city') {
      payload['targetState'] = (_selectedState ?? '').trim();
      payload['targetCity'] = (_selectedCity ?? '').trim();
    }

    return payload;
  }

  double get _estimatedTotalCost {
    final estimate = _estimate;
    if (estimate == null) return 0;
    final audience = int.tryParse(_targetAudienceSizeController.text.trim()) ??
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
        _targetAudienceSizeController.text =
            estimate.selectedAudienceSize.toString();
        _estimatedAudienceSizeController.text =
            estimate.audienceCount.toString();
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
        if (_selectedOfferId == null || _selectedOffer == null) {
          error = 'Please select an offer.';
        } else if (_selectedBannerUrl == null || _selectedBannerUrl!.isEmpty) {
          error = 'Please select one offer banner.';
        }
        break;
      case 1:
        if (_targetMode == 'pincode' &&
            _pincodeController.text.trim().isEmpty) {
          error = 'Pincode is required for pincode mode.';
        } else if (_targetMode == 'state' &&
            (_selectedState ?? '').trim().isEmpty) {
          error = 'State is required for state-wise mode.';
        } else if (_targetMode == 'city') {
          if ((_selectedState ?? '').trim().isEmpty) {
            error = 'State is required for city-wise mode.';
          } else if ((_selectedCity ?? '').trim().isEmpty) {
            error = 'City is required for city-wise mode.';
          }
        }
        break;
      case 2:
        if (_channels.isEmpty) {
          error = 'Select at least one delivery channel.';
        } else if (_estimate == null) {
          error = 'Estimate the audience before continuing.';
        } else {
          final target =
              int.tryParse(_targetAudienceSizeController.text.trim()) ?? 0;
          if (target <= 0) {
            error = 'Target audience size must be greater than 0.';
          } else if (target > _estimate!.audienceCount) {
            error = 'Target audience cannot exceed estimated audience.';
          }
        }
        break;
      case 3:
        if (_scheduledAt == null) {
          error = 'Please select campaign schedule date & time.';
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
      _selectedBannerUrl = null;
      _failedBannerUrls.clear();
    });
  }

  String _bannerErrorText(Object error) {
    final message = error.toString();
    if (error is SocketException || message.contains('Failed host lookup')) {
      return 'Cannot load banner: network/DNS issue.';
    }
    return 'Banner preview unavailable.';
  }

  Widget _buildBannerErrorBox({
    required String imageUrl,
    required String message,
    required double height,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _failedBannerUrls.remove(imageUrl);
        });
      },
      child: Container(
        height: height,
        color: AppColors.highlight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap to retry',
              style: TextStyle(color: AppColors.accent, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerImage(
    String imageUrl, {
    required double height,
    required double width,
    BoxFit fit = BoxFit.cover,
  }) {
    if (_failedBannerUrls.contains(imageUrl)) {
      return _buildBannerErrorBox(
        imageUrl: imageUrl,
        message: 'Cannot load banner: network/DNS issue.',
        height: height,
      );
    }

    return Image.network(
      imageUrl,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: height,
          width: width,
          color: AppColors.highlight,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, error, ___) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_failedBannerUrls.add(imageUrl)) {
            setState(() {});
          }
        });
        return _buildBannerErrorBox(
          imageUrl: imageUrl,
          message: _bannerErrorText(error),
          height: height,
        );
      },
    );
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledAt != null
          ? TimeOfDay.fromDateTime(_scheduledAt!)
          : TimeOfDay.fromDateTime(now.add(const Duration(minutes: 15))),
    );
    if (time == null || !mounted) return;

    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      _scheduledAt = scheduled;
    });
  }

  Future<void> _createCampaign({required bool submitForPayment}) async {
    for (var step = 0; step <= 3; step += 1) {
      if (!_validateStep(step)) {
        setState(() => _currentStep = step);
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final campaign =
          await CampaignService.instance.createCampaign(_campaignPayload());
      if (submitForPayment) {
        await CampaignService.instance.payCampaign(
          campaign.id,
          paymentMethod: 'upi',
        );
        emitSaleClosedReward(campaign.id);
      }
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
            _createCampaign(submitForPayment: true);
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
          if (isLast) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: (_submitting || _estimating)
                        ? null
                        : () => _createCampaign(submitForPayment: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                    ),
                    child: const Text('Pay & Launch'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: (_submitting || _estimating)
                        ? null
                        : () => _createCampaign(submitForPayment: false),
                    child: const Text('Save Draft'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: (_submitting || _estimating)
                        ? null
                        : details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.borderMid),
                    ),
                    child: const Text('Back'),
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: (_submitting || _estimating)
                        ? null
                        : details.onStepContinue,
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: (_submitting || _estimating)
                        ? null
                        : details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.borderMid),
                    ),
                    child: Text(_currentStep == 0 ? 'Close' : 'Back'),
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Offer & Banner'),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
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
                if (_selectedOffer != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _selectedBannerUrl != null &&
                              _selectedBannerUrl!.isNotEmpty
                          ? 'Banner selected ✓'
                          : 'Select one banner from this offer',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: _selectedBannerUrl != null &&
                                    _selectedBannerUrl!.isNotEmpty
                                ? AppColors.success
                                : Theme.of(context).textTheme.titleSmall?.color,
                          ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (_selectedOffer != null && _selectedOffer!.photos.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderMid),
                    ),
                    child: const Text(
                        'Selected offer has no banners/photos. Please upload offer banners first.'),
                  ),
                if (_selectedOffer != null && _selectedOffer!.photos.isNotEmpty)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _selectedOffer!.photos.map((photoUrl) {
                      final isSelected = _selectedBannerUrl == photoUrl;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedBannerUrl = photoUrl);
                        },
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.borderMid,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: AspectRatio(
                            aspectRatio: 1.9,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildBannerImage(
                                photoUrl,
                                height: double.infinity,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('Audience'),
            isActive: _currentStep >= 1,
            content: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _targetMode,
                  decoration:
                      const InputDecoration(labelText: 'Targeting mode'),
                  items: const [
                    DropdownMenuItem(value: 'pincode', child: Text('Pincode')),
                    DropdownMenuItem(value: 'city', child: Text('City-wise')),
                    DropdownMenuItem(
                        value: 'pan_india', child: Text('Pan India')),
                    DropdownMenuItem(value: 'state', child: Text('State-wise')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _targetMode = value;
                      if (value == 'pincode') {
                        _selectedState = null;
                        _selectedCity = null;
                        _cities = const [];
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_targetMode == 'pincode')
                  TextFormField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(labelText: 'Pincode'),
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 12),
                if (_targetMode == 'state')
                  DropdownButtonFormField<String>(
                    initialValue: _selectedState,
                    decoration: InputDecoration(
                      labelText: 'State',
                      helperText: _loadingStates ? 'Loading states...' : null,
                    ),
                    items: _states
                        .map((state) =>
                            DropdownMenuItem(value: state, child: Text(state)))
                        .toList(),
                    onChanged: _loadingStates ? null : _onStateSelected,
                  ),
                if (_targetMode == 'city') ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedState,
                    decoration: InputDecoration(
                      labelText: 'State',
                      helperText: _loadingStates ? 'Loading states...' : null,
                    ),
                    items: _states
                        .map((state) =>
                            DropdownMenuItem(value: state, child: Text(state)))
                        .toList(),
                    onChanged: _loadingStates ? null : _onStateSelected,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCity,
                    decoration: InputDecoration(
                      labelText: 'City',
                      helperText: _loadingCities
                          ? 'Loading cities...'
                          : _selectedState == null
                              ? 'Select state first'
                              : null,
                    ),
                    items: _cities
                        .map((city) =>
                            DropdownMenuItem(value: city, child: Text(city)))
                        .toList(),
                    onChanged: (_loadingCities || _selectedState == null)
                        ? null
                        : (value) {
                            setState(() => _selectedCity = value);
                          },
                  ),
                ],
                if (_targetMode == 'pan_india')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderMid),
                    ),
                    child: const Text(
                        'Pan India selected. Campaign will target all eligible customers in India.'),
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
                ..._channelOptions.map((option) {
                  final selected = _channels.contains(option.key);
                  final subtitle = option.key == 'app_inbox' &&
                          _estimate != null
                      ? 'Rs ${_estimate!.inboxUnitPrice.toStringAsFixed(2)} per message'
                      : option.subtitle;
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selected,
                    onChanged: option.enabled
                        ? (value) {
                            setState(() {
                              if (value == true) {
                                _channels.add(option.key);
                              } else {
                                _channels.remove(option.key);
                              }
                            });
                          }
                        : null,
                    title: Text(option.label),
                    subtitle: Text(subtitle),
                  );
                }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _targetAudienceSizeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Target Audience',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _estimatedAudienceSizeController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Estimated Audience',
                        ),
                      ),
                    ),
                  ],
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
            title: const Text('Campaign Schedule'),
            isActive: _currentStep >= 3,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  onPressed: _pickSchedule,
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(
                    _scheduledAt == null
                        ? 'Select Campaign Schedule'
                        : 'Change Schedule',
                  ),
                ),
                const SizedBox(height: 12),
                if (_scheduledAt != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _scheduledAt!.toLocal().toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                if (_selectedBannerUrl != null &&
                    _selectedBannerUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildBannerImage(
                      _selectedBannerUrl!,
                      height: 180,
                      width: double.infinity,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 4,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewTile(
                    label: 'Offer', value: _selectedOffer?.title ?? '-'),
                _ReviewTile(
                  label: 'Banner',
                  value: _selectedBannerUrl?.isNotEmpty == true
                      ? 'Selected'
                      : 'Not selected',
                ),
                _ReviewTile(
                  label: 'Targeting',
                  value: _targetMode == 'pan_india'
                      ? 'Pan India'
                      : _targetMode == 'city'
                          ? 'State: ${_selectedState ?? '-'}, City: ${_selectedCity ?? '-'}'
                          : _targetMode == 'state'
                              ? 'State: ${_selectedState ?? '-'}'
                              : 'Pincode: ${_pincodeController.text.trim()}',
                ),
                _ReviewTile(label: 'Channels', value: _channels.join(', ')),
                _ReviewTile(
                  label: 'Estimated audience',
                  value: _estimate?.audienceCount.toString() ?? 'Not estimated',
                ),
                _ReviewTile(
                  label: 'Target audience',
                  value: _targetAudienceSizeController.text.trim().isEmpty
                      ? '-'
                      : _targetAudienceSizeController.text.trim(),
                ),
                _ReviewTile(
                  label: 'Estimated total',
                  value: 'Rs ${_estimatedTotalCost.toStringAsFixed(2)}',
                ),
                _ReviewTile(
                  label: 'Schedule',
                  value: _scheduledAt?.toLocal().toString() ?? '-',
                ),
                if (_selectedBannerUrl != null &&
                    _selectedBannerUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildBannerImage(
                      _selectedBannerUrl!,
                      height: 160,
                      width: double.infinity,
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

class _ChannelOption {
  final String key;
  final String label;
  final bool enabled;
  final String subtitle;

  const _ChannelOption({
    required this.key,
    required this.label,
    required this.enabled,
    required this.subtitle,
  });
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
