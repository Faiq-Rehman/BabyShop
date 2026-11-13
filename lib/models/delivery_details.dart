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

  final String fullName;
  final String phone;
  final String province;
  final String city;
  final String area;
  final String address;
  final String landmark;
  final String postalCode;
  final String deliveryInstructions;

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
