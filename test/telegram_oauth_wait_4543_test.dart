import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_login/social_login/default_login_types/telegram_oauth_wait.dart';

void main() {
  test('веб с колбэками бота идёт в диалог, без них кнопка скрыта', () {
    expect(
      routeTelegramLogin(isWeb: false, messengerReady: false),
      TelegramLoginRoute.oauthApp,
    );
    expect(
      routeTelegramLogin(isWeb: false, messengerReady: true),
      TelegramLoginRoute.oauthApp,
    );
    expect(
      routeTelegramLogin(isWeb: true, messengerReady: true),
      TelegramLoginRoute.messengerBot,
    );
    expect(
      routeTelegramLogin(isWeb: true, messengerReady: false),
      TelegramLoginRoute.hidden,
    );
  });

  test('пауза приложения не тратит таймаут', () {
    var now = DateTime(2026);
    final wait = TelegramOauthWait(
      timeout: const Duration(seconds: 60),
      now: () => now,
    );
    wait.advance();
    now = now.add(const Duration(seconds: 30));
    wait.notePause();
    now = now.add(const Duration(minutes: 5));
    wait.noteResume();
    now = now.add(const Duration(seconds: 29));
    wait.advance();
    expect(wait.expired, isFalse);
    expect(wait.active, const Duration(seconds: 59));
    now = now.add(const Duration(seconds: 1));
    wait.advance();
    expect(wait.expired, isTrue);
  });

  test('возврат прерывает сон и читает пользователя', () async {
    var calls = 0;
    final wait = TelegramOauthWait(
      timeout: const Duration(minutes: 5),
      now: () => DateTime(2026),
    );
    final user = await waitTelegramOauth<String>(
      wait: wait,
      isLoggedIn: () async {
        calls++;
        return calls > 1;
      },
      readUser: () async => 'user',
      delay: (_) async {
        if (calls == 1) wait.noteResume();
      },
      interval: const Duration(seconds: 30),
    );
    expect(user, 'user');
    expect(calls, 2);
  });

  test('активный таймаут без входа возвращает null', () async {
    var now = DateTime(2026);
    final wait = TelegramOauthWait(
      timeout: const Duration(milliseconds: 500),
      now: () => now,
    );
    final user = await waitTelegramOauth<String>(
      wait: wait,
      isLoggedIn: () async => false,
      readUser: () async => 'user',
      delay: (step) async {
        now = now.add(step);
      },
      interval: const Duration(milliseconds: 200),
      slice: const Duration(milliseconds: 200),
    );
    expect(user, isNull);
    expect(wait.expired, isTrue);
  });

  test('отказ проверки пробрасывается', () {
    final wait = TelegramOauthWait(
      timeout: const Duration(minutes: 5),
      now: () => DateTime(2026),
    );
    expect(
      () => waitTelegramOauth<String>(
        wait: wait,
        isLoggedIn: () async => throw StateError('rejected'),
        readUser: () async => 'user',
        delay: (_) async {},
      ),
      throwsA(isA<StateError>()),
    );
  });
}
