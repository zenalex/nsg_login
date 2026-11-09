import 'dart:async';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_data/nsg_data.dart';
import 'package:nsg_data/authorize/nsg_login_response.dart';
import 'package:nsg_login/social_login/max_auth/max_auth.dart';

const payload = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
final state = '$payload.${List.filled(64, 'b').join()}';
Map<String, dynamic> challenge() => {
  'payload': payload,
  'state': state,
  'expiresIn': 300,
};

class Provider extends NsgDataProvider {
  Provider()
    : super(
        applicationName: 'test',
        firebaseToken: '',
        applicationVersion: '0',
        availableServers: NsgServerParams({}, ''),
        serverUri: 'https://test.invalid',
      );
  int polls = 0, cancels = 0;
  final requests = <String, Map<String, dynamic>?>{};
  Future<Map<String, dynamic>?> Function()? begin;
  Future<Map<String, dynamic>?> Function()? poll;
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
    expect(method, 'POST');
    requests[function!] = params;
    switch (function) {
      case 'MaxLoginBegin':
        return begin == null ? challenge() : begin!();
      case 'MaxPoll':
        polls++;
        return poll == null ? {'errorCode': 0} : poll!();
      case 'MaxLoginCancel':
        cancels++;
        expect(params?['state'], state);
        return {};
    }
    throw StateError('unexpected method');
  }

  @override
  Future<NsgLoginResponse> requestSocialMethod({
    String? function,
    required String methodName,
    Map<String, dynamic>? params,
  }) => throw StateError('poll must not mutate provider token');
}

MaxAuth auth(
  Provider p,
  List<Uri> opened, {
  Duration timeout = const Duration(seconds: 1),
  bool opens = true,
}) => MaxAuth(
  provider: p,
  botUsername: 'test_bot',
  botId: '123',
  timeout: timeout,
  pollInterval: Duration.zero,
  launcher: (uri) async {
    opened.add(uri);
    return opens;
  },
);

class RecordingLauncher extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;
  LaunchOptions? options;
  String? url;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    this.url = url;
    this.options = options;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'canonical link contains only public payload; handoff keeps full proof',
    () async {
      final p = Provider()..token = 'existing';
      final links = <Uri>[];
      final a = auth(p, links);
      await a.launchMax();
      expect(links.single.toString(), 'https://max.ru/test_bot?start=$payload');
      expect(links.single.toString(), isNot(contains(state)));
      expect(await a.waitForConfirmation(), isTrue);
      expect(a.takeConfirmedState(), state);
      expect(p.requests['MaxPoll']?['state'], state);
      expect(p.token, 'existing');
      await a.cancel();
      expect(p.cancels, 0);
      expect(() => a.takeConfirmedState(), throwsStateError);
    },
  );
  test('pending then confirmed does not loop after success', () async {
    final p = Provider();
    p.poll = () async => {'errorCode': p.polls == 1 ? 40400 : 0};
    final a = auth(p, []);
    await a.launchMax();
    expect(await a.waitForConfirmation(), isTrue);
    expect(p.polls, 2);
    a.takeConfirmedState();
  });
  test(
    'launch failure cancels exactly once and never opens bare messenger',
    () async {
      final p = Provider();
      final links = <Uri>[];
      final a = auth(p, links, opens: false);
      await expectLater(a.launchMax(), throwsStateError);
      await a.cancel();
      expect(links, hasLength(1));
      expect(p.cancels, 1);
    },
  );
  test(
    'cancel interrupts an in-flight poll and late response cannot succeed',
    () async {
      final p = Provider();
      final reply = Completer<Map<String, dynamic>?>();
      p.poll = () => reply.future;
      final a = auth(p, []);
      await a.launchMax();
      final result = a.waitForConfirmation();
      await a.cancel();
      expect(await result, isFalse);
      reply.complete({'errorCode': 0});
      await Future<void>.delayed(Duration.zero);
      expect(() => a.takeConfirmedState(), throwsStateError);
      expect(p.cancels, 1);
    },
  );
  test(
    'cancel during begin cleans up returned challenge without launching',
    () async {
      final p = Provider();
      final begin = Completer<Map<String, dynamic>?>();
      p.begin = () => begin.future;
      final links = <Uri>[];
      final a = auth(p, links);
      final opening = a.launchMax();
      await a.cancel();
      begin.complete(challenge());
      await opening;
      expect(links, isEmpty);
      expect(p.cancels, 1);
    },
  );
  test('timeout cancels pending server challenge', () async {
    final p = Provider();
    final a = auth(p, [], timeout: Duration.zero);
    await a.launchMax();
    expect(await a.waitForConfirmation(), isFalse);
    expect(p.cancels, 1);
    expect(p.polls, 0);
  });
  for (final code in [403, 40402]) {
    test('terminal code $code stops polling and cancels', () async {
      final p = Provider()
        ..poll = (() async => {
          'errorCode': code,
          'isError': true,
          'errorMessage': 'denied',
        });
      final a = auth(p, []);
      await a.launchMax();
      await expectLater(
        a.waitForConfirmation(),
        throwsA(isA<NsgApiException>()),
      );
      expect(p.polls, 1);
      expect(p.cancels, 1);
    });
  }
  test(
    'malformed empty poll response is never authentication success',
    () async {
      final p = Provider()..poll = (() async => {});
      final a = auth(p, []);
      await a.launchMax();
      await expectLater(a.waitForConfirmation(), throwsStateError);
      expect(p.cancels, 1);
    },
  );
  test(
    'legacy bare state in Begin is rejected before opening messenger',
    () async {
      final p = Provider()
        ..begin = (() async => {
          'payload': payload,
          'state': payload,
          'expiresIn': 300,
        });
      final links = <Uri>[];
      final a = auth(p, links);
      await expectLater(a.launchMax(), throwsStateError);
      expect(links, isEmpty);
    },
  );
  test('real launcher explicitly keeps source tab with blank target', () async {
    final old = UrlLauncherPlatform.instance;
    final recorder = RecordingLauncher();
    UrlLauncherPlatform.instance = recorder;
    try {
      final a = MaxAuth(
        provider: Provider(),
        botUsername: 'test_bot',
        botId: '123',
      );
      await a.launchMax();
      expect(recorder.options!.webOnlyWindowName, '_blank');
      expect(recorder.url, 'https://max.ru/test_bot?start=$payload');
      expect(a.startCommand, '/start $payload');
      expect(a.startCommand, isNot(contains(state)));
      await a.cancel();
    } finally {
      UrlLauncherPlatform.instance = old;
    }
  });
  test(
    'returning focus wakes long interval without concurrent polling',
    () async {
      final p = Provider();
      final first = Completer<void>();
      p.poll = () async {
        if (p.polls == 1) {
          first.complete();
          return {'errorCode': 40400};
        }
        return {'errorCode': 0};
      };
      final a = MaxAuth(
        provider: p,
        botUsername: 'test_bot',
        botId: '123',
        pollInterval: const Duration(seconds: 30),
        launcher: (_) async => true,
      );
      await a.launchMax();
      final result = a.waitForConfirmation();
      await first.future;
      a.requestPoll();
      expect(await result.timeout(const Duration(seconds: 1)), isTrue);
      expect(p.polls, 2);
      a.takeConfirmedState();
    },
  );
}
