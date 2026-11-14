import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nsg_controls/nsg_button.dart';
import 'package:nsg_controls/localization/nsg_controls_localizations.dart';
import 'package:nsg_data/nsg_data.dart';
import 'package:nsg_login/l10n/nsg_login_localizations.dart';
import 'package:nsg_login/social_login/default_login_types/max_default_login.dart';

Never _originalMaxFailure(Object error) => throw error;

class _Provider extends NsgDataProvider {
  _Provider(this.failure)
    : super(
        applicationName: 'test',
        firebaseToken: '',
        applicationVersion: '0',
        availableServers: NsgServerParams({}, ''),
      );
  final Object failure;
  Completer<Map<String, dynamic>?>? pendingPoll;
  final pollStarted = Completer<void>();
  int cancels = 0;
  @override
  Future<Map<String, dynamic>?> baseRequest({
    String? function,
    Map<String, dynamic>? params,
    Map<String, String?>? headers,
    String? url,
    Duration? timeout,
    String method = 'GET',
    bool autoRepeate = false,
    int autoRepeateCount = 1000,
    int maxRepeateDelay = 5,
    FutureOr<bool> Function(Exception)? retryIf,
    FutureOr<void> Function(Exception)? onRetry,
  }) async {
    if (function == 'MaxLoginBegin') {
      return {
        'payload': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'state':
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.${List.filled(64, 'b').join()}',
        'expiresIn': 300,
      };
    }
    if (function == 'MaxLoginCancel') {
      cancels++;
      return {};
    }
    expect(function, 'MaxPoll');
    if (!pollStarted.isCompleted) pollStarted.complete();
    if (pendingPoll != null) return pendingPoll!.future;
    _originalMaxFailure(failure);
  }
}

void main() {
  const launcher = MethodChannel('plugins.flutter.io/url_launcher');
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcher, null);
    Get.reset();
  });
  for (final hasHandler in [false, true]) {
    testWidgets(
      hasHandler
          ? 'MAX forwards original error to external callback once'
          : 'MAX preserves original stack without an external callback',
      (tester) async {
        Get.testMode = true;
        final failure = StateError('synthetic auth failure');
        final received = <Object>[];
        var successes = 0;
        var launches = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(launcher, (_) async {
              launches++;
              return true;
            });
        await tester.pumpWidget(
          GetMaterialApp(
            localizationsDelegates: const [
              ...NsgLoginLocalizations.localizationsDelegates,
              NsgControlsLocalizations.delegate,
            ],
            supportedLocales: NsgLoginLocalizations.supportedLocales,
            home: Scaffold(
              body: MaxLoginWidget(
                botId: 'test',
                botUsername: 'test',
                provider: _Provider(failure),
                buttonText: 'MAX',
                onLoginSuccess: (_) => successes++,
                onAuthError: hasHandler
                    ? (error) => received.add(error as Object)
                    : null,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final button = tester.widget<NsgButton>(find.byType(NsgButton));
        Object? caught;
        StackTrace? stack;
        await tester.runAsync(() async {
          try {
            await (button.onPressed as dynamic)();
          } catch (error, trace) {
            caught = error;
            stack = trace;
          }
        });
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expect(launches, greaterThan(0));
        expect(successes, 0);
        if (hasHandler) {
          expect(received, [same(failure)]);
          expect(caught, isNull);
        } else {
          expect(caught, same(failure));
          expect(
            stack.toString(),
            contains('_originalMaxFailure'),
            reason: 'The rethrow must retain the failing auth frame',
          );
          expect(received, isEmpty);
        }
      },
    );
  }
  testWidgets('closing MAX dialog cancels polling and ignores late success', (
    tester,
  ) async {
    Get.testMode = true;
    final provider = (await tester.runAsync(
      () async =>
          _Provider(StateError('unused'))
            ..pendingPoll = Completer<Map<String, dynamic>?>(),
    ))!;
    var successes = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcher, (_) async => true);
    await tester.pumpWidget(
      GetMaterialApp(
        localizationsDelegates: const [
          ...NsgLoginLocalizations.localizationsDelegates,
          NsgControlsLocalizations.delegate,
        ],
        supportedLocales: NsgLoginLocalizations.supportedLocales,
        home: Scaffold(
          body: MaxLoginWidget(
            botId: 'test',
            botUsername: 'test',
            provider: provider,
            buttonText: 'MAX',
            onLoginSuccess: (_) => successes++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<dynamic>? login;
    final button = tester.widget<NsgButton>(find.byType(NsgButton));
    await tester.runAsync(() async {
      login = (button.onPressed as dynamic)() as Future<dynamic>;
      await provider.pollStarted.future.timeout(const Duration(seconds: 5));
    });
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      provider.pendingPoll!.complete({'errorCode': 0});
      await login?.timeout(const Duration(seconds: 5));
    });
    await tester.pump();
    expect(provider.cancels, 1);
    expect(successes, 0);
    expect(tester.takeException(), isNull);
  });
}
