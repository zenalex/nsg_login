import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nsg_controls/localization/nsg_controls_localizations.dart';
import 'package:nsg_controls/nsg_button.dart';
import 'package:nsg_login/l10n/nsg_login_localizations.dart';
import 'package:nsg_login/social_login/default_login_types/telegram_default_login.dart';
import 'package:telegram_login_flutter/telegram_login_flutter.dart';

const _failed =
    'Не удалось войти через Telegram. Подтвердите вход в Telegram и попробуйте снова.';

class _Gateway implements TelegramOauthGateway {
  _Gateway(this._check, {this.user});

  final Future<bool> Function() _check;
  final TelegramUser? user;

  @override
  Future<void> start(String phoneNumber) async {}

  @override
  Future<bool> checkLoginStatus() => _check();

  @override
  Future<TelegramUser?> getUserData() async => user;
}

void main() {
  tearDown(Get.reset);

  Future<void> pump(WidgetTester tester, TelegramLoginWidget widget) async {
    Get.testMode = true;
    await tester.pumpWidget(
      GetMaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          ...NsgLoginLocalizations.localizationsDelegates,
          NsgControlsLocalizations.delegate,
        ],
        supportedLocales: NsgLoginLocalizations.supportedLocales,
        home: Scaffold(body: widget),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester) async {
    final button = tester.widget<NsgButton>(find.byType(NsgButton));
    await tester.runAsync(() async {
      await (button.onPressed as dynamic)();
    });
    await tester.pump();
  }

  Future<void> flush(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('таймаут показывает ошибку на диалоге', (tester) async {
    var now = DateTime(2026);
    var checks = 0;
    await pump(
      tester,
      TelegramLoginWidget(
        botId: 'bot',
        botDomain: 'example.test',
        buttonText: 'Telegram',
        timeout: const Duration(milliseconds: 500),
        pollInterval: const Duration(milliseconds: 200),
        now: () => now,
        delay: (step) async {
          now = now.add(step);
        },
        oauth: (_, _) => _Gateway(() async {
          checks++;
          return false;
        }),
        onLoginSuccess: (_) => fail('входа не было'),
      ),
    );

    await press(tester);

    expect(checks, greaterThan(0));
    expect(find.byKey(const ValueKey('telegramLogin.error')), findsOneWidget);
    expect(find.text(_failed), findsOneWidget);
    await flush(tester);
  });

  testWidgets('отказ проверки показывает ту же ошибку', (tester) async {
    final received = <Object>[];
    await pump(
      tester,
      TelegramLoginWidget(
        botId: 'bot',
        botDomain: 'example.test',
        buttonText: 'Telegram',
        oauth: (_, _) => _Gateway(() async => throw StateError('rejected')),
        onAuthError: (error) => received.add(error as Object),
        onLoginSuccess: (_) => fail('входа не было'),
      ),
    );

    await press(tester);

    expect(received, hasLength(1));
    expect(received.single, isA<StateError>());
    expect(find.text(_failed), findsOneWidget);
    await flush(tester);
  });

  testWidgets('возврат в приложение проверяет статус сразу', (tester) async {
    var checks = 0;
    TelegramUser? signed;
    final user = TelegramUser(
      id: '1',
      firstName: 'A',
      lastName: '',
      username: 'a',
      photoUrl: '',
      authDate: '1',
      hash: 'h',
      rawJson: '{}',
    );
    await pump(
      tester,
      TelegramLoginWidget(
        botId: 'bot',
        botDomain: 'example.test',
        buttonText: 'Telegram',
        timeout: const Duration(seconds: 2),
        pollInterval: const Duration(seconds: 30),
        oauth: (_, _) => _Gateway(() async {
          checks++;
          return checks > 1;
        }, user: user),
        onLoginSuccess: (value) => signed = value,
      ),
    );

    final button = tester.widget<NsgButton>(find.byType(NsgButton));
    await tester.runAsync(() async {
      final done = (button.onPressed as dynamic)();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await done;
    });
    await tester.pump();

    expect(signed?.id, '1');
    expect(checks, 2);
    expect(find.text(_failed), findsNothing);
    await flush(tester);
  });
}
