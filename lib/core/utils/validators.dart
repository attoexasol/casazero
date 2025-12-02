class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  static bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return false;
    return true;
  }

  static List<PasswordRequirement> getPasswordRequirements(String password) {
    return [
      PasswordRequirement(
        label: 'password_length',
        isMet: password.length >= 8,
      ),
      PasswordRequirement(
        label: 'password_uppercase',
        isMet: RegExp(r'[A-Z]').hasMatch(password),
      ),
      PasswordRequirement(
        label: 'password_lowercase',
        isMet: RegExp(r'[a-z]').hasMatch(password),
      ),
      PasswordRequirement(
        label: 'password_number',
        isMet: RegExp(r'[0-9]').hasMatch(password),
      ),
      PasswordRequirement(
        label: 'password_special',
        isMet: RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
      ),
    ];
  }
}

class PasswordRequirement {
  final String label;
  final bool isMet;

  PasswordRequirement({required this.label, required this.isMet});
}