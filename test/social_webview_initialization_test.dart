import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_login/l10n/nsg_login_localizations.dart';
import 'package:nsg_login/pages/nsg_social_login_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.windows);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test(
    'missing WebView2 selects browser without constructing environment',
    () async {
      var created = false;
      expect(
        await NsgSocialLoginWidget.init(
          availableVersion: () async => null,
          createEnvironment: () async {
            created = true;
            throw StateError('unexpected');
          },
        ),
        isFalse,
      );
      expect(created, isFalse);
    expect(NsgSocialLoginWidget.initializationFailureStage, 'runtime_missing');
    },
  );

  test('factory failure is awaited and reported, never async void', () async {
    final errors = <Object>[];
    expect(
      await NsgSocialLoginWidget.init(
        availableVersion: () async => '123',
        createEnvironment: () async => throw StateError('factory failed'),
        onError: (e, _) => errors.add(e),
      ),
      isFalse,
    );
    expect(errors.single, isA<StateError>());
    expect(NsgSocialLoginWidget.initializationFailureStage, 'create_environment');
    expect(NsgSocialLoginWidget.webViewEnvironment, isNull);
  });

  testWidgets('browser failure permits retry, no embedded view is created', (
    tester,
  ) async {
    await NsgSocialLoginWidget.init(availableVersion: () async => null);
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: NsgLoginLocalizations.localizationsDelegates,
        supportedLocales: NsgLoginLocalizations.supportedLocales,
        home: Scaffold(
          body: NsgSocialLoginWidget(
            authUrl: 'https://example.invalid/auth',
            onVerify: (_) async {},
            externalLauncher: (_) async {
              calls++;
              return calls > 1;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('social-external-browser')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
