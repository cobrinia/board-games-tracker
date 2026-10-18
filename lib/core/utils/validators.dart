/// Form field validators. Each returns an error message, or null when the
/// value is valid, so they plug straight into `TextFormField.validator`.
///
/// This is local validation only: it checks the format before a request is
/// sent. Whether the account exists or the password is right is decided by
/// Firebase Authentication, and those errors are shown separately.
class Validators {
  Validators._();

  static const int minPasswordLength = 8;
  static const int maxNameLength = 30;

  static final RegExp _email = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$",
  );
  static final RegExp _letter = RegExp(r'[A-Za-zА-Яа-яІіЇїЄєҐґ]');
  static final RegExp _digit = RegExp(r'\d');

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'This field is required' : null;

  /// User name: required, 2–30 characters, not only digits or symbols.
  static String? name(
    String? value, {
    String emptyMessage = 'Please enter your name',
  }) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return emptyMessage;
    if (name.length < 2) return 'Name is too short (min 2 characters)';
    if (name.length > maxNameLength) {
      return 'Name is too long (max $maxNameLength characters)';
    }
    if (!_letter.hasMatch(name)) return 'Name must contain letters';
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email';
    if (!_email.hasMatch(email)) return 'Please enter a valid email address';
    return null;
  }

  /// Sign-in password: only required. The password policy is not checked
  /// here, otherwise old accounts with shorter passwords could not sign in.
  static String? password(String? value) =>
      (value == null || value.isEmpty) ? 'Please enter your password' : null;

  /// New password (registration, change password).
  static String? newPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Please enter a password';
    if (password.length < minPasswordLength) {
      return 'At least $minPasswordLength characters';
    }
    if (password.contains(' ')) return 'Password must not contain spaces';
    if (!_letter.hasMatch(password) || !_digit.hasMatch(password)) {
      return 'Use both letters and numbers';
    }
    return null;
  }

  /// Validator for a "confirm password" field. [password] is read on every
  /// call, so pass a function that returns the current text.
  static String? Function(String?) confirmPassword(
    String Function() password,
  ) => (value) {
    if (value == null || value.isEmpty) return 'Please repeat the password';
    return value == password() ? null : 'Passwords do not match';
  };

  /// Image link for a profile photo: must be a full https:// URL.
  static String? httpsUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please paste an image link';
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.isAbsolute || uri.host.isEmpty) {
      return 'This is not a valid link';
    }
    if (uri.scheme != 'https') return 'The link must start with https://';
    return null;
  }

  static String? positiveInt(String? value) {
    final number = int.tryParse(value ?? '');
    return (number == null || number <= 0) ? 'Enter a number' : null;
  }
}
