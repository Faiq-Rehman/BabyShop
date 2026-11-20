import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/delivery_details.dart';
import '../../services/shop_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _provinces = [
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Islamabad Capital Territory',
    'Gilgit-Baltistan',
    'Azad Jammu and Kashmir',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _instructionsController = TextEditingController();

  String? _province;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _postalCodeController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final doc = await context.read<ShopRepository>().getUserProfile();
      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data() ?? {};
        final rawDelivery = data['deliveryDetails'] as Map<String, dynamic>?;
        final delivery = DeliveryDetails.fromMap(rawDelivery);

        final name = (data['name'] as String?)?.trim();
        final phone = (data['phone'] as String?)?.trim();

        _nameController.text = (name?.isNotEmpty == true)
            ? name!
            : (delivery.fullName.isNotEmpty
                ? delivery.fullName
                : (user.displayName ?? ''));

        _phoneController.text = (phone?.isNotEmpty == true)
            ? phone!
            : (delivery.phone.isNotEmpty
                ? delivery.phone
                : (user.phoneNumber ?? ''));

        if (delivery.province.isNotEmpty &&
            _provinces.contains(delivery.province)) {
          _province = delivery.province;
        }
        _cityController.text = delivery.city;
        _areaController.text = delivery.area;
        _addressController.text = delivery.address;
        _landmarkController.text = delivery.landmark;
        _postalCodeController.text = delivery.postalCode;
        _instructionsController.text = delivery.deliveryInstructions;
      } else {
        _nameController.text = user.displayName ?? '';
        _phoneController.text = user.phoneNumber ?? '';
      }
    } catch (error) {
      if (mounted) {
        showErrorMessage(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final details = DeliveryDetails(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        province: _province ?? '',
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        address: _addressController.text.trim(),
        landmark: _landmarkController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        deliveryInstructions: _instructionsController.text.trim(),
      );

      await context.read<ShopRepository>().updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        deliveryDetails: details,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.midnight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.gold, width: 1),
          ),
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.gold, size: 20),
              SizedBox(width: 10),
              Text(
                'Profile & delivery address saved successfully.',
                style: TextStyle(
                  color: AppColors.ivory,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        showErrorMessage(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : Form(
              key: _formKey,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.ivory,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.warmBeige, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.midnight.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.midnight,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.gold, width: 1.8),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.gold,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text
                                        : (user?.displayName ?? 'Valued Customer'),
                                    style: const TextStyle(
                                      fontFamily: 'PlayfairDisplay',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.midnight,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    user?.email ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Personal Information
                      _profileSection(
                        icon: Icons.badge_outlined,
                        title: 'Personal Information',
                        subtitle: 'Your identity and contact details',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Full name *',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) =>
                                  Validators.requiredField(value, 'full name', minimum: 3),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              initialValue: user?.email ?? '',
                              readOnly: true,
                              enabled: false,
                              decoration: const InputDecoration(
                                labelText: 'Email address (Account credential)',
                                prefixIcon: Icon(Icons.mail_outline),
                                suffixIcon: Icon(Icons.lock_outline, size: 18, color: AppColors.gold),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Mobile number *',
                                hintText: '03XX XXXXXXX',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: Validators.validatePhone,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Delivery & Address Details
                      _profileSection(
                        icon: Icons.location_on_outlined,
                        title: 'Default Delivery Address',
                        subtitle: 'Pre-filled automatically on checkout for effortless orders',
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _province,
                              decoration: const InputDecoration(
                                labelText: 'Province / Region *',
                                prefixIcon: Icon(Icons.map_outlined),
                              ),
                              items: _provinces
                                  .map(
                                    (prov) => DropdownMenuItem(
                                      value: prov,
                                      child: Text(prov),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) => setState(() => _province = val),
                              validator: (val) => val == null
                                  ? 'Select your province or region.'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _cityController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'City *',
                                prefixIcon: Icon(Icons.location_city_outlined),
                              ),
                              validator: (value) =>
                                  Validators.requiredField(value, 'city'),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _areaController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Area / Locality *',
                                hintText: 'e.g. DHA Phase 6 / Gulberg',
                                prefixIcon: Icon(Icons.place_outlined),
                              ),
                              validator: (value) =>
                                  Validators.requiredField(value, 'area or locality'),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _addressController,
                              minLines: 2,
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'House / Building and Street Address *',
                                hintText: 'House number, building, street',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.home_outlined),
                              ),
                              validator: (value) => Validators.requiredField(
                                value,
                                'complete street address',
                                minimum: 5,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _landmarkController,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nearby Landmark (optional)',
                                prefixIcon: Icon(Icons.near_me_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _postalCodeController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Postal Code (optional)',
                                prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _instructionsController,
                              minLines: 2,
                              maxLines: 3,
                              maxLength: 300,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Delivery Instructions (optional)',
                                hintText: 'Special gate code, call before arrival, etc.',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.edit_note_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Changes Button
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.ivory,
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          _isSaving ? 'Saving Profile...' : 'Save Profile & Address',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: AppColors.ivory,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _profileSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warmBeige, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warmBeige,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Icon(icon, color: AppColors.midnight, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.midnight,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
