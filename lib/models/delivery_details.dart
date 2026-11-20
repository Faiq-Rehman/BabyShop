class DeliveryDetails {
  const DeliveryDetails({
    required this.fullName,
    required this.phone,
    required this.province,
    required this.city,
    required this.area,
    required this.address,
    this.landmark = '',
    this.postalCode = '',
    this.deliveryInstructions = '',
  });

  factory DeliveryDetails.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const DeliveryDetails(
        fullName: '',
        phone: '',
        province: '',
        city: '',
        area: '',
        address: '',
      );
    }
    return DeliveryDetails(
      fullName: (map['fullName'] as String?)?.trim() ?? '',
      phone: (map['phone'] as String?)?.trim() ?? '',
      province: (map['province'] as String?)?.trim() ?? '',
      city: (map['city'] as String?)?.trim() ?? '',
      area: (map['area'] as String?)?.trim() ?? '',
      address: (map['address'] as String?)?.trim() ?? '',
      landmark: (map['landmark'] as String?)?.trim() ?? '',
      postalCode: (map['postalCode'] as String?)?.trim() ?? '',
      deliveryInstructions:
          (map['deliveryInstructions'] as String?)?.trim() ?? '',
    );
  }

  final String fullName;
  final String phone;
  final String province;
  final String city;
  final String area;
  final String address;
  final String landmark;
  final String postalCode;
  final String deliveryInstructions;

  bool get isComplete =>
      fullName.trim().length >= 3 &&
      phone.trim().length >= 10 &&
      province.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      area.trim().isNotEmpty &&
      address.trim().length >= 5;

  String get formattedAddress => [
    address,
    area,
    city,
    province,
    if (postalCode.isNotEmpty) postalCode,
    'Pakistan',
  ].join(', ');

  Map<String, String> toMap() => {
    'fullName': fullName.trim(),
    'phone': phone.trim(),
    'province': province.trim(),
    'city': city.trim(),
    'area': area.trim(),
    'address': address.trim(),
    'landmark': landmark.trim(),
    'postalCode': postalCode.trim(),
    'deliveryInstructions': deliveryInstructions.trim(),
    'country': 'Pakistan',
  };
}
