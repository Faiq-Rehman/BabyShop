import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/error_widget.dart';
import '../../models/delivery_details.dart';
import '../../services/shop_repository.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({required this.items, required this.subtotal, super.key});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> items;
  final double subtotal;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
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
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _instructionsController = TextEditingController();
  String? _province;
  bool _placingOrder = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
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

  String? _required(String? value, String label, {int minimum = 2}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length < minimum) return 'Enter your $label.';
    return null;
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _placingOrder = true);
    try {
      final details = DeliveryDetails(
        fullName: _nameController.text,
        phone: _phoneController.text,
        province: _province!,
        city: _cityController.text,
        area: _areaController.text,
        address: _addressController.text,
        landmark: _landmarkController.text,
        postalCode: _postalCodeController.text,
        deliveryInstructions: _instructionsController.text,
      );
      final receipt = await context.read<ShopRepository>().placeOrder(
        deliveryDetails: details,
      );
      if (!mounted) return;
      final continueShopping = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.ivory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.warmBeige,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.gold,
              size: 46,
            ),
          ),
          title: const Text(
            'Order Confirmed!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              color: AppColors.midnight,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Order #${receipt.orderId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.midnight,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Total: \$${receipt.total.toStringAsFixed(2)}\nPayment: Cash on Delivery',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.ivory,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Continue Shopping'),
              ),
            ),
          ],
        ),
      );
      if (continueShopping == true && mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) showErrorMessage(context, error);
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.items.fold<int>(
      0,
      (itemCountSoFar, item) =>
          itemCountSoFar + ((item.data()['quantity'] as num?)?.toInt() ?? 1),
    );
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                _checkoutSection(
                  icon: Icons.location_on_outlined,
                  title: 'Delivery Address',
                  subtitle: 'Where should we deliver your luxury package?',
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
                            _required(value, 'recipient name', minimum: 3),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Mobile number *',
                          hintText: '03XX XXXXXXX',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) {
                          final phone = (value ?? '').replaceAll(
                            RegExp(r'[\s()-]'),
                            '',
                          );
                          return RegExp(r'^(?:(?:\+|00)?92|0)?3\d{9}$')
                                  .hasMatch(phone)
                              ? null
                              : 'Enter a valid Pakistani mobile number.';
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _province,
                        decoration: const InputDecoration(
                          labelText: 'Province / Region *',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        items: _provinces
                            .map(
                              (province) => DropdownMenuItem(
                                value: province,
                                child: Text(province),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _province = value),
                        validator: (value) => value == null
                            ? 'Select your province or region.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cityController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                        validator: (value) => _required(value, 'city'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _areaController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Area / Locality *',
                          hintText: 'e.g. DHA Phase 6',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                        validator: (value) =>
                            _required(value, 'area or locality'),
                      ),
                      const SizedBox(height: 12),
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
                        validator: (value) => _required(
                          value,
                          'complete street address',
                          minimum: 5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _landmarkController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nearby Landmark (optional)',
                          prefixIcon: Icon(Icons.near_me_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _postalCodeController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Postal Code (optional)',
                          prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _instructionsController,
                        minLines: 2,
                        maxLines: 3,
                        maxLength: 300,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Delivery Instructions (optional)',
                          hintText: 'Special instructions for the courier',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.edit_note_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _checkoutSection(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Order Summary',
                  subtitle: '$itemCount item${itemCount == 1 ? '' : 's'} in your bag',
                  child: Column(
                    children: [
                      ...widget.items.map((item) {
                        final data = item.data();
                        final quantity =
                            (data['quantity'] as num?)?.toInt() ?? 1;
                        final price = (data['price'] as num?)?.toDouble() ?? 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${data['name'] as String? ?? 'Product'} × $quantity',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.midnight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '\$${(price * quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.midnight,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: AppColors.warmBeige),
                      ),
                      _summaryLine('Subtotal', widget.subtotal),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Boutique Delivery',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          Text(
                            'COMPLIMENTARY',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: AppColors.warmBeige),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warmBeige,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: _summaryLine(
                          'Grand Total',
                          widget.subtotal,
                          emphasized: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _checkoutSection(
                  icon: Icons.payments_outlined,
                  title: 'Payment Method',
                  subtitle: 'Safe and secure upon delivery',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warmBeige,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                    ),
                    child: const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.money, color: AppColors.gold, size: 28),
                      title: Text(
                        'Cash on Delivery',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: AppColors.midnight,
                        ),
                      ),
                      subtitle: Text(
                        'Please have the exact amount ready upon delivery.',
                        style: TextStyle(fontSize: 12, color: AppColors.navy),
                      ),
                      trailing: Icon(
                        Icons.check_circle,
                        color: AppColors.gold,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _placingOrder ? null : _placeOrder,
                  icon: _placingOrder
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.ivory,
                          ),
                        )
                      : const Icon(Icons.lock_outline, size: 18),
                  label: Text(
                    _placingOrder
                        ? 'Placing Order...'
                        : 'Place Order · \$${widget.subtotal.toStringAsFixed(2)}',
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
                const SizedBox(height: 10),
                const Text(
                  'By placing your order, you agree to pay the displayed total on delivery.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.navy),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkoutSection({
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
                          fontFamily: 'Georgia',
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

  Widget _summaryLine(String label, double amount, {bool emphasized = false}) {
    final style = TextStyle(
      fontFamily: emphasized ? 'Georgia' : null,
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
      fontSize: emphasized ? 18 : 13.5,
      color: AppColors.midnight,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text('\$${amount.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
