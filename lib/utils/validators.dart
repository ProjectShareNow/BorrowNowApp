class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validateEmailOrRegisterId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or Register ID is required';
    }
    final trimmed = value.trim();
    if (trimmed.contains('@')) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(trimmed)) {
        return 'Please enter a valid email address';
      }
    } else {
      if (trimmed.length < 3) {
        return 'Please enter a valid Register ID';
      }
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateConfirmPassword(
    String? value,
    String originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateRegisterNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'College register number is required';
    }
    if (value.trim().length < 4) {
      return 'Please enter a valid register number';
    }
    return null;
  }

  static String? validateItemTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Item name is required';
    }
    if (value.trim().length < 3) {
      return 'Item name must be at least 3 characters';
    }
    return null;
  }

  static String? validateItemDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length < 10) {
      return 'Please provide a detailed description (at least 10 characters)';
    }
    return null;
  }

  static String? validatePickupLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pickup location is required';
    }
    return null;
  }

  static String? validateDuration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Borrow duration is required';
    }
    return null;
  }
}
