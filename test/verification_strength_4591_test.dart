import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nsg_data/nsg_data.dart';
import 'package:nsg_data/password/nsg_login_password_strength.dart';
import 'package:nsg_login/l10n/nsg_login_localizations.dart';
import 'package:nsg_login/messenger_phone_flow.dart';
import 'package:nsg_login/nsg_login_params.dart';
import 'package:nsg_login/pages/nsg_login_page/nsg_login_page_new.dart';

class _Provider extends NsgDataProvider {
  _Provider()
    : super(
        applicationName: 'verification-4591',
        applicationVersion: '0',
        firebaseToken: '',
        availableServers: NsgServerParams({
          'https://example.invalid': 'test',
        }, 'https://example.invalid'),
      );
}

class _Params extends NsgLoginParams {
  _Params()
    : super(
        useCaptcha: false,
        useEmailLogin: false,
        usePhoneLogin: true,
        usePasswordLogin: true,
        headerMessageLogin: 'Sign in',
        headerMessageRegistration: 'Register',
        textSendSms: 'Send code',
        textEnterCode: 'Code',
        textEnterPassword: 'Password',
        textEnterNewPassword: 'New password',
        textEnterPasswordAgain: 'Repeat password',
        textConfirm: 'Confirm',
        textEnter: 'Sign in',
        textTelegramRecovery: 'Code in Telegram',
        passwordIndicator: (value) => value.length < 6
            ? PasswordStrength.weak
            : PasswordStrength.strong,
        requestTelegramRecovery: (phone, channel) async {
          recoveries.add('$channel:$phone');
          return const MessengerPhoneRecoveryResult('Code sent to the chat');
        },
        errorMessageByStatusCode: (code) => 'status:$code',
      );

  static final recoveries = <String>[];
  final errors = <String>[];

  @override
  void showError(BuildContext? context, String message, {int delayed = 5}) {
    errors.add(message);
  }
}

/// #4591: восстановление через бота ведёт со входа прямо на код и новый
/// пароль, минуя регистрацию. Индикатор силы пароля не должен ронять build.
void main() {
  tearDown(() {
    _Params.recoveries.clear();
    Get.reset();
  });

  testWidgets(
    'messenger recovery opens verification with password strength, no crash',
    (tester) async {
      final params = _Params();
      await tester.pumpWidget(
        GetMaterialApp(
          localizationsDelegates: NsgLoginLocalizations.localizationsDelegates,
          supportedLocales: NsgLoginLocalizations.supportedLocales,
          home: NsgLoginPageNew(_Provider(), widgetParams: () => params),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1));

      await tester.enterText(find.byType(TextFormField).first, '79990001122');
      await tester.tap(find.text('Code in Telegram'));
      await tester.pumpAndSettle();

      expect(_Params.recoveries, ['telegram:+7 (999) 000-11-22']);
      expect(tester.takeException(), isNull);
      expect(find.text('Code sent to the chat'), findsWidgets);
      final newPassword = find.widgetWithText(TextFormField, 'New password');
      expect(newPassword, findsOneWidget);

      // Ввод нового пароля обновляет индикатор, тоже без падения.
      await tester.enterText(newPassword, 'Strong-pass-1');
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(params.errors, isEmpty);
    },
  );
}
