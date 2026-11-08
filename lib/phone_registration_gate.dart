import 'package:nsg_data/authorize/nsg_login_model.dart';

/// Телефон на регистрации и восстановлении пароля. Вход по паролю сюда не входит.
bool phoneRegistrationVisible({
  required bool usePhoneLogin,
  required bool usePhoneRegistration,
}) => usePhoneLogin && usePhoneRegistration;

/// Без SMS-регистрации восстановление идёт по почте, если почта включена.
NsgLoginType registrationIdentityType({
  required NsgLoginType current,
  required bool usePhoneRegistration,
  required bool useEmailLogin,
}) {
  if (!usePhoneRegistration && useEmailLogin && current == NsgLoginType.phone) {
    return NsgLoginType.email;
  }
  return current;
}

/// Запрос кода по телефону на регистрации и восстановлении. Вход по паролю не блокирует.
bool phoneRegistrationCodeBlocked({
  required NsgLoginType loginType,
  required bool usePhoneRegistration,
}) => !usePhoneRegistration && loginType == NsgLoginType.phone;
