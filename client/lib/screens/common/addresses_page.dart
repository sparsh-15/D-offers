import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/theme_helper.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';

/// My Addresses page – view and edit primary address (shared for Customer).
class AddressesPage extends StatefulWidget {
  const AddressesPage({
    super.key,
    this.onSaved,
  });

  final VoidCallback? onSaved;

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  UserModel? _user;
  bool _loading = true;
  bool _saving = false;
  late final TextEditingController _addressController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _pincodeController = TextEditingController();
    _cityController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = await AuthService.instance.fetchCurrentUser();
      if (!mounted) return;
      setState(() {
        _user = user;
        _addressController.text = user.address;
        _pincodeController.text = user.pincode;
        _cityController.text = user.city;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AuthService.instance.updateCurrentUser(
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty
            ? null
            : _pincodeController.text.trim(),
      );
      if (!mounted) return;
      widget.onSaved?.call();
      await _load();
      DialogHelper.showSuccessSnackBar(context, 'Address updated');
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('My Addresses'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.home_rounded, color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Primary address',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _pincodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Pincode',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                  border: OutlineInputBorder(),
                                ),
                                readOnly: true,
                                onTap: () {
                                  // City can be updated via pincode lookup elsewhere; keep read-only here for simplicity
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_saving ? 'Saving...' : 'Save address'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
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
