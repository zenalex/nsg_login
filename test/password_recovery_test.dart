import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nsg_data/authorize/nsg_login_model.dart';
import 'package:nsg_data/authorize/nsg_login_response.dart';
import 'package:nsg_data/nsg_data.dart';
import 'package:nsg_data/password/nsg_login_password_strength.dart';
import 'package:nsg_login/l10n/nsg_login_localizations.dart';
import 'package:nsg_login/nsg_login_params.dart';
import 'package:nsg_login/pages/nsg_login_page.dart' as legacy;
import 'package:nsg_login/pages/nsg_login_page/nsg_login_page_new.dart';

class _Provider extends NsgDataProvider {
  _Provider()
    : super(
        applicationName: 'recovery-test',
        applicationVersion: '0',
        firebaseToken: '',
        availableServers: NsgServerParams({
          'https://example.invalid': 'test',
        }, 'https://example.invalid'),
      );

  final requests = <String>[];
  NsgLoginResponse response = NsgLoginResponse(errorCode: 0);

  @override
  Future<NsgLoginResponse> phoneLoginPassword({
    required String phoneNumber,
    required String securityCode,
    NsgLoginType? loginType,
  }) async {
    requests.add(securityCode);
    return response;
  }

  @override
  Future<NsgLoginResponse> phoneLogin({
    required String phoneNumber,
    required String securityCode,
    bool? register,
    String? newPassword,
    NsgLoginType? loginType,
    String? firebaseToken,
  }) async => response;
}

class _Params extends NsgLoginParams {
  _Params({PasswordStrength Function(String)? strength})
    : super(
        useCaptcha: false,
        useEmailLogin: true,
        usePhoneLogin: false,
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
        passwordIndicator: strength ?? (_) => PasswordStrength.strong,
        errorMessageByStatusCode: (code) => 'status:$code',
      );

  final errors = <String>[];

  @override
  void showError(BuildContext? context, String message, {int delayed = 5}) {
    errors.add(message);
  }
}

void main() {
  tearDown(Get.reset);
  for (final modern in [true, false]) {
    final variant = modern ? 'current' : 'legacy';

    Future<dynamic> mount(
      WidgetTester tester,
      _Provider provider,
      _Params params,
    ) async {
      final dynamic page = modern
          ? NsgLoginPageNew(
              provider,
              initialEmail: 'test@example.invalid',
              widgetParams: () => params,
            )
          : legacy.NsgLoginPage(
              provider,
              initialEmail: 'test@example.invalid',
              widgetParams: () => params,
            );
      await tester.pumpWidget(
        GetMaterialApp(
          localizationsDelegates: NsgLoginLocalizations.localizationsDelegates,
          supportedLocales: NsgLoginLocalizations.supportedLocales,
          home: page as Widget,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1));
      return page;
    }

    if (modern) {
      testWidgets(
        'current: password focus survives strength and visibility changes',
        (tester) async {
          final provider = _Provider();
          final params = _Params(
            strength: (value) => value.length < 3
                ? PasswordStrength.veryWeak
                : PasswordStrength.strong,
          );
          await mount(tester, provider, params);
          await tester.tap(find.text('REGISTER').first);
          await tester.pump();
          await tester.tap(find.text('SEND CODE'));
          await tester.pump();
          final password = find.widgetWithText(TextFormField, 'New password');
          final editable = find.descendant(
            of: password,
            matching: find.byType(EditableText),
          );
          await tester.tap(password);
          await tester.pump();
          final original = tester.state<EditableTextState>(editable);
          expect(original.widget.focusNode.hasFocus, isTrue);

          for (final value in ['a', 'ab', 'abc', 'Pasted-password-123']) {
            await tester.enterText(password, value);
            await tester.pump();
            expect(tester.state<EditableTextState>(editable), same(original));
            expect(original.widget.focusNode.hasFocus, isTrue);
            expect(original.widget.controller.text, value);
          }

          await tester.tap(
            find.descendant(of: password, matching: find.byType(IconButton)),
          );
          await tester.pump();
          expect(tester.state<EditableTextState>(editable), same(original));
          expect(original.widget.controller.text, 'Pasted-password-123');
          expect(original.widget.obscureText, isFalse);
          expect(original.widget.focusNode.hasFocus, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('$variant: resend cooldown opens editable password form', (
      tester,
    ) async {
      final provider = _Provider()
        ..response = NsgLoginResponse.fromJson({
          'errorCode': 40300,
          'isError': true,
          'secondsBeforeRepeat': 60.0,
        });
      final params = _Params();
      await mount(tester, provider, params);
      await tester.tap(find.text('REGISTER').first);
      await tester.pump();
      await tester.tap(find.text('SEND CODE'));
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Code'), findsOneWidget);
      expect(params.errors, isEmpty);
      expect(provider.requests, ['']);
      final password = find.widgetWithText(TextFormField, 'New password');
      await tester.tap(password);
      await tester.enterText(password, 'Example-password-123');
      await tester.pump();
      expect(
        find
            .descendant(of: password, matching: find.byType(EditableText))
            .evaluate()
            .single
            .widget,
        isA<EditableText>().having(
          (field) => field.controller.text,
          'text',
          'Example-password-123',
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('$variant: 40300 without delay is still an error', (
      tester,
    ) async {
      final provider = _Provider()
        ..response = NsgLoginResponse(errorCode: 40300, isError: true);
      final params = _Params();
      await mount(tester, provider, params);
      await tester.tap(find.text('REGISTER').first);
      await tester.pump();
      await tester.tap(find.text('SEND CODE'));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, 'Code'), findsNothing);
      expect(params.errors, ['status:40300']);
    });

    testWidgets('$variant: registration callback does not send old password', (
      tester,
    ) async {
      final provider = _Provider();
      final params = _Params();
      final page = await mount(tester, provider, params);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'old-password',
      );
      await tester.tap(find.text('REGISTER').first);
      await tester.pump();
      page.sendData();
      await tester.pump();
      expect(provider.requests, ['']);
      expect(find.widgetWithText(TextFormField, 'Code'), findsOneWidget);
    });

    testWidgets('$variant: password sign-in still sends the password', (
      tester,
    ) async {
      final provider = _Provider()
        ..response = NsgLoginResponse(errorCode: 40304, isError: true);
      final params = _Params();
      final page = await mount(tester, provider, params);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'sign-in-password',
      );
      page.sendData();
      await tester.pump();
      expect(provider.requests, ['sign-in-password']);
      expect(params.errors, ['status:40304']);
    });

    testWidgets(
      '$variant: wrong verification code is never a successful recovery',
      (tester) async {
        final provider = _Provider();
        final params = _Params();
        await mount(tester, provider, params);
        await tester.tap(find.text('REGISTER').first);
        await tester.pump();
        await tester.tap(find.text('SEND CODE'));
        await tester.pump();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Code'),
          '123456',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'New password'),
          'Example-password-123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Repeat password'),
          'Example-password-123',
        );
        provider.response = NsgLoginResponse.fromJson({
          'errorCode': 40300,
          'isError': true,
          'secondsBeforeRepeat': 60.0,
        });
        await tester.ensureVisible(find.text('CONFIRM'));
        await tester.tap(find.text('CONFIRM'));
        await tester.pump();
        expect(find.widgetWithText(TextFormField, 'Code'), findsOneWidget);
        expect(params.errors, ['status:40300']);
      },
    );
  }
}
