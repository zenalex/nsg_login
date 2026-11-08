import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_data/authorize/nsg_login_model.dart';
import 'package:nsg_login/phone_registration_gate.dart';

void main() {
  test('вход по телефону не зависит от запрета SMS-регистрации', () {
    expect(
      phoneRegistrationVisible(usePhoneLogin: true, usePhoneRegistration: false),
      isFalse,
    );
    expect(
      phoneRegistrationVisible(usePhoneLogin: true, usePhoneRegistration: true),
      isTrue,
    );
    expect(
      phoneRegistrationVisible(usePhoneLogin: false, usePhoneRegistration: true),
      isFalse,
    );
  });

  test('восстановление с телефона уходит на почту, если почта включена', () {
    expect(
      registrationIdentityType(
        current: NsgLoginType.phone,
        usePhoneRegistration: false,
        useEmailLogin: true,
      ),
      NsgLoginType.email,
    );
    expect(
      registrationIdentityType(
        current: NsgLoginType.phone,
        usePhoneRegistration: true,
        useEmailLogin: true,
      ),
      NsgLoginType.phone,
    );
    expect(
      registrationIdentityType(
        current: NsgLoginType.email,
        usePhoneRegistration: false,
        useEmailLogin: true,
      ),
      NsgLoginType.email,
    );
  });

  test('код по телефону на регистрации блокируется, вход по паролю — нет', () {
    expect(
      phoneRegistrationCodeBlocked(loginType: NsgLoginType.phone, usePhoneRegistration: false),
      isTrue,
    );
    expect(
      phoneRegistrationCodeBlocked(loginType: NsgLoginType.email, usePhoneRegistration: false),
      isFalse,
    );
    expect(
      phoneRegistrationCodeBlocked(loginType: NsgLoginType.phone, usePhoneRegistration: true),
      isFalse,
    );
  });
}
