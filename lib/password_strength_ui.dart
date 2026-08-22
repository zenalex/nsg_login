import 'package:flutter/material.dart';
import 'package:nsg_data/password/nsg_login_password_strength.dart';

/// Представление [PasswordStrength] — цвета и подписи для индикатора стойкости
/// пароля. Живёт здесь, а не в `nsg_data`: слой данных отдаёт только сам
/// перечислимый тип, вся визуальная часть — в пакете логина.

Color passwordStrengthColor(PasswordStrength value) {
  switch (value) {
    case PasswordStrength.veryWeak:
      return Colors.red;
    case PasswordStrength.weak:
      return Colors.orange;
    case PasswordStrength.medium:
      return Colors.yellow;
    case PasswordStrength.strong:
      return Colors.green;
    case PasswordStrength.veryStrong:
      return Colors.greenAccent;
  }
}

String passwordStrengthMessage(PasswordStrength value) {
  switch (value) {
    case PasswordStrength.veryWeak:
      return 'Very weak';
    case PasswordStrength.weak:
      return 'Weak';
    case PasswordStrength.medium:
      return 'Medium';
    case PasswordStrength.strong:
      return 'Strong';
    case PasswordStrength.veryStrong:
      return 'Very strong';
  }
}

Iterable<Color> passwordStrengthColors = PasswordStrength.values.map((value) => passwordStrengthColor(value));
Iterable<String> passwordStrengthMessages = PasswordStrength.values.map((value) => passwordStrengthMessage(value));
