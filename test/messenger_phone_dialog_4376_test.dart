import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_login/messenger_phone_dialog.dart';
import 'package:nsg_login/messenger_phone_flow.dart';

void main() {
  test('пароль обязателен только у новой учётки', () {
    expect(
      messengerPasswordStep('required'),
      MessengerPasswordStep.requirePassword,
    );
    expect(
      messengerPasswordStep('missing'),
      MessengerPasswordStep.offerPassword,
    );
    expect(messengerPasswordStep('set'), MessengerPasswordStep.enterApp);
    expect(messengerPasswordStep(''), MessengerPasswordStep.enterApp);
    expect(messengerPasswordStep(null), MessengerPasswordStep.enterApp);
  });

  const text = MessengerPhoneDialogText(
    registerTitle: 'Регистрация по телефону',
    recoveryTitle: 'Восстановление по телефону',
    steps: 'Откроется бот Futbolista',
    recoverySteps: 'Код придёт в чат',
    phoneHint: 'Номер',
    invalidPhone: 'Введите корректный номер',
    waiting: 'Ждём подтверждения в боте.',
    openAgain: 'Открыть бота ещё раз',
    chooseOther: 'Выбрать другой мессенджер',
    cancel: 'Отмена',
    unavailable: 'Сейчас подтвердить номер не получается.',
  );

  Future<void> open(
    WidgetTester tester, {
    required Future<MessengerPhoneBeginResult> Function(
      String phone,
      String channel,
    )
    begin,
    required Future<MessengerPhonePollResult> Function(
      String payload,
      bool Function() cancelled,
    )
    poll,
    List<String>? opened,
    String Function(int code)? errorText,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => MessengerPhoneDialog(
                    intent: MessengerPhoneIntent.access,
                    text: text,
                    begin: begin,
                    poll: poll,
                    errorText: errorText ?? (code) => 'отказ $code',
                    phoneValid: (phone) => phone.trim().length >= 9,
                    openUrl: (url) async {
                      opened?.add(url);
                    },
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('messengerPhone.phone')),
      '79990001122',
    );
  }

  testWidgets('диалог → Begin → ожидание → отмена старого Poll', (
    tester,
  ) async {
    final begins = <String>[];
    final opened = <String>[];
    var firstCancelled = false;
    final firstEntered = Completer<void>();
    await open(
      tester,
      opened: opened,
      begin: (phone, channel) async {
        begins.add(channel);
        return MessengerPhoneBeginResult(
          url: 'https://t.me/FutbolistaBot?start=$channel',
          payload: channel,
        );
      },
      poll: (payload, cancelled) async {
        if (payload == 'telegram') {
          if (!firstEntered.isCompleted) firstEntered.complete();
          while (!cancelled()) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
          }
          firstCancelled = true;
          return const MessengerPhonePollResult(cancelled: true);
        }
        return const MessengerPhonePollResult(errorCode: 50301);
      },
    );

    await tester.tap(find.byKey(const ValueKey('messengerPhone.telegram')));
    await tester.pump();
    await firstEntered.future.timeout(const Duration(seconds: 2));
    await tester.pump();

    expect(begins, ['telegram']);
    expect(opened, ['https://t.me/FutbolistaBot?start=telegram']);
    expect(
      find.byKey(const ValueKey('messengerPhone.waiting')),
      findsOneWidget,
    );
    expect(find.text('Откроется бот Futbolista'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('messengerPhone.other')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(firstCancelled, isTrue);
    expect(find.byKey(const ValueKey('messengerPhone.waiting')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('messengerPhone.max')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(begins, ['telegram', 'max']);
    expect(find.text('отказ 50301'), findsOneWidget);
    expect(find.byKey(const ValueKey('messengerPhone.waiting')), findsNothing);
  });

  testWidgets('Begin 503 остаётся текстом в диалоге и Poll не стартует', (
    tester,
  ) async {
    var polls = 0;
    await open(
      tester,
      begin: (_, _) async => const MessengerPhoneBeginResult(errorCode: 50301),
      poll: (_, _) async {
        polls++;
        return const MessengerPhonePollResult(pending: true);
      },
    );

    await tester.tap(find.byKey(const ValueKey('messengerPhone.telegram')));
    await tester.pumpAndSettle();

    expect(polls, 0);
    expect(find.text('отказ 50301'), findsOneWidget);
    expect(find.byKey(const ValueKey('messengerPhone.waiting')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'восстановление со ссылкой открывает бота и не уходит на код сразу',
    (tester) async {
      final opened = <String>[];
      MessengerPhoneDialogOutcome? outcome;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  outcome = await showDialog<MessengerPhoneDialogOutcome>(
                    context: context,
                    builder: (_) => MessengerPhoneDialog(
                      intent: MessengerPhoneIntent.recovery,
                      text: text,
                      begin: (_, __) async =>
                          const MessengerPhoneBeginResult(errorCode: 50301),
                      poll: (_, __) async =>
                          const MessengerPhonePollResult(errorCode: 50301),
                      recovery: (_, __) async =>
                          const MessengerPhoneRecoveryResult(
                            'Если номер есть, код отправлен.',
                            url: 'https://t.me/FutbolistaBot?start=abc',
                          ),
                      errorText: (code) => 'отказ $code',
                      phoneValid: (phone) => phone.trim().length >= 9,
                      openUrl: (url) async {
                        opened.add(url);
                      },
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('messengerPhone.phone')),
        '79990001122',
      );
      expect(
        find.byKey(const ValueKey('messengerPhone.telegram')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('messengerPhone.max')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('messengerPhone.telegram')));
      await tester.pumpAndSettle();

      expect(opened, ['https://t.me/FutbolistaBot?start=abc']);
      expect(
        find.byKey(const ValueKey('messengerPhone.waiting')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('messengerPhone.enterCode')),
        findsOneWidget,
      );
      expect(outcome, isNull);

      await tester.tap(find.byKey(const ValueKey('messengerPhone.enterCode')));
      await tester.pumpAndSettle();
      expect(outcome?.recoveryMessage, 'Если номер есть, код отправлен.');
      expect(tester.takeException(), isNull);
    },
  );

  Future<void> openFixed(
    WidgetTester tester, {
    required String channel,
    required List<String> begins,
    required List<String> opened,
    String? initialPhone,
    Completer<void>? polling,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => MessengerPhoneDialog(
                    intent: MessengerPhoneIntent.access,
                    text: text,
                    fixedChannel: channel,
                    initialPhone: initialPhone,
                    begin: (phone, chosen) async {
                      begins.add('$chosen:$phone');
                      return MessengerPhoneBeginResult(
                        url: 'https://t.me/FutbolistaBot?start=$chosen',
                        payload: chosen,
                      );
                    },
                    poll: (_, cancelled) async {
                      if (polling != null && !polling.isCompleted) {
                        polling.complete();
                      }
                      while (!cancelled()) {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 20),
                        );
                      }
                      return const MessengerPhonePollResult(cancelled: true);
                    },
                    errorText: (code) => 'отказ $code',
                    phoneValid: (phone) => phone.trim().length >= 9,
                    openUrl: (url) async {
                      opened.add(url);
                    },
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
  }

  testWidgets('прямой вход не спрашивает канал и открывает нажатый', (
    tester,
  ) async {
    final begins = <String>[];
    final opened = <String>[];
    final polling = Completer<void>();
    await openFixed(
      tester,
      channel: 'telegram',
      initialPhone: '79990001122',
      begins: begins,
      opened: opened,
      polling: polling,
    );
    await polling.future.timeout(const Duration(seconds: 2));
    await tester.pump();

    expect(begins, ['telegram:79990001122']);
    expect(opened, ['https://t.me/FutbolistaBot?start=telegram']);
    expect(find.text('Откроется бот Futbolista'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('messengerPhone.waiting')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('messengerPhone.telegram')), findsNothing);
    expect(find.byKey(const ValueKey('messengerPhone.max')), findsNothing);
    expect(find.byKey(const ValueKey('messengerPhone.other')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('messengerPhone.cancel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('прямой MAX без номера ждёт номер и шлёт max', (tester) async {
    final begins = <String>[];
    final opened = <String>[];
    final polling = Completer<void>();
    await openFixed(
      tester,
      channel: 'max',
      begins: begins,
      opened: opened,
      polling: polling,
    );

    expect(find.byKey(const ValueKey('messengerPhone.telegram')), findsNothing);
    expect(find.byKey(const ValueKey('messengerPhone.max')), findsNothing);
    expect(find.byKey(const ValueKey('messengerPhone.open')), findsOneWidget);
    expect(begins, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('messengerPhone.phone')),
      '79990001122',
    );
    await tester.tap(find.byKey(const ValueKey('messengerPhone.open')));
    await polling.future.timeout(const Duration(seconds: 2));
    await tester.pump();

    expect(begins, hasLength(1));
    expect(begins.single, startsWith('max:'));
    expect(begins.single, contains('999'));
    expect(opened, ['https://t.me/FutbolistaBot?start=max']);
    expect(
      find.byKey(const ValueKey('messengerPhone.waiting')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('messengerPhone.cancel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.takeException(), isNull);
  });
}
