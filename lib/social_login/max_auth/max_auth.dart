import 'dart:async';
import 'dart:math';

import 'package:nsg_data/nsg_data_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Вход через мессенджер MAX по актуальной схеме Bot API (deep-link + webhook).
///
/// Старый путь (oauth.max.ru + скрейп HTML + проверка hash) умер: домен
/// oauth.max.ru больше не существует, а MAX перешёл на платформу
/// platform-api2.max.ru с подтверждением входа через webhook бота.
///
/// Поток:
///   1. генерим одноразовый [nonce];
///   2. [launchMax] открывает бота: web.max.ru/<bot>?startapp=<nonce>;
///   3. пользователь жмёт «Запустить» — MAX шлёт webhook на НАШ сервер,
///      сервер связывает nonce с пользователем MAX;
///   4. [waitForConfirmation] поллит наш сервер (MaxPoll) до подтверждения;
///   5. финальный обмен nonce -> app-токен делает verifyFunction = LoginMax
///      (через штатный SocialLoginProvider.processVerify).
///
/// Клиент ходит ТОЛЬКО на наш сервер (provider.serverUri) — никакого
/// кросс-доменного fetch, поэтому CORS на вебе не возникает.
class MaxAuth {
  MaxAuth({
    required this.provider,
    required this.botUsername,
    required this.botId,
    this.timeout = const Duration(seconds: 90),
    this.pollInterval = const Duration(seconds: 2),
  }) : nonce = _generateNonce();

  final NsgDataProvider provider;
  final String botUsername;
  final String botId;
  final Duration timeout;
  final Duration pollInterval;

  /// Одноразовый идентификатор сессии входа, передаётся в deep-link как startapp
  /// и обратно — в webhook бота. По нему сервер связывает MAX-пользователя.
  final String nonce;

  static String _generateNonce() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Открывает бота MAX с нашим nonce в startapp-payload.
  Future<void> launchMax() async {
    final candidates = <Uri>[
      Uri.parse('https://web.max.ru/$botUsername?startapp=$nonce'),
      Uri.parse('https://web.max.ru/$botId?startapp=$nonce'),
      Uri.parse('https://web.max.ru'),
    ];
    for (final uri in candidates) {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    }
    throw Exception('Could not open MAX');
  }

  /// Поллит наш сервер (MaxPoll), пока webhook не свяжет [nonce] с пользователем.
  /// Возвращает true при подтверждении, false — при таймауте.
  Future<bool> waitForConfirmation() async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final resp = await provider.requestSocialMethod(
        function: 'MaxPoll',
        methodName: 'MaxPoll',
        params: {'state': nonce},
      );
      // errorCode == 0 -> сервер увидел подтверждение от webhook.
      // Любой другой код (40400 pending / 40402 expired / сетевой сбой) -> ждём.
      if (resp.errorCode == 0) {
        return true;
      }
      await Future.delayed(pollInterval);
    }
    return false;
  }
}
