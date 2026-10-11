/// Placeholder form validators. Real rules will be added together with
/// the backend integration.
class Validators {
  Validators._();

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'This field is required' : null;

  static String? email(String? value) {
    if (value == null || !RegExp(r'^\S+@\S+\.\S+$').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 8) return 'At least 8 characters';
    return null;
  }

  static String? positiveInt(String? value) {
    final number = int.tryParse(value ?? '');
    return (number == null || number <= 0) ? 'Enter a number' : null;
  }
}
