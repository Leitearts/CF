/// Client-side validation only catches obvious mistakes before a network
/// call is made (Stage 4 section 20). The backend remains authoritative --
/// these never replace server-side validation, only pre-empt wasted requests.
class Validators {
  Validators._();

  static String? required(String? value, {String fieldLabel = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel is required.';
    }
    return null;
  }

  static String? emailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email or phone number.';
    }
    final trimmed = value.trim();
    final looksLikeEmail = trimmed.contains('@');
    if (looksLikeEmail) {
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(trimmed)) {
        return 'Enter a valid email address.';
      }
    } else {
      final phoneRegex = RegExp(r'^[0-9+\-\s]{7,15}$');
      if (!phoneRegex.hasMatch(trimmed)) {
        return 'Enter a valid phone number.';
      }
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter your password.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'Enter your full name.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String fieldLabel = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel is required.';
    }
    final parsed = num.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number.';
    }
    if (parsed <= 0) {
      return '$fieldLabel must be greater than zero.';
    }
    return null;
  }
}
