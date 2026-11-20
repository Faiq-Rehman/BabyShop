abstract final class Validators {
  static final RegExp _pakistanPhoneRegex =
      RegExp(r'^(?:(?:\+|00)?92|0)?3\d{9}$');

  static String? requiredField(
    String? value,
    String label, {
    int minimum = 2,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length < minimum) return 'Enter your $label.';
    return null;
  }

  static String? validatePhone(String? value) {
    final phone = (value ?? '').replaceAll(RegExp(r'[\s()-]'), '');
    return _pakistanPhoneRegex.hasMatch(phone)
        ? null
        : 'Enter a valid Pakistani mobile number.';
  }
}
