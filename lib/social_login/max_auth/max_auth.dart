import 'dart:async';

import 'package:nsg_data/nsg_data.dart';
import 'package:nsg_data/authorize/nsg_login_response.dart';
import 'package:url_launcher/url_launcher.dart';

/// Login state stays in the initiating browser. Only payload goes to the bot.
class MaxAuth {
  MaxAuth({
    required this.provider,
    required this.botUsername,
    required this.botId,
    this.timeout = const Duration(seconds: 90),
    this.pollInterval = const Duration(seconds: 2),
    Future<bool> Function(Uri)? launcher,
  }) : _launcher =
           launcher ??
           ((uri) => launchUrl(
             uri,
             mode: LaunchMode.externalApplication,
             webOnlyWindowName: '_blank',
           ));

  final NsgDataProvider provider;
  final String botUsername;
  final String botId;
  final Duration timeout;
  final Duration pollInterval;
  final Future<bool> Function(Uri) _launcher;
  final _cancelledSignal = Completer<void>();
  var _pollWake = Completer<void>();
  String? _state;
  String? _payload;
  DateTime? _expires;
  bool _cancelled = false;
  bool _cancelSent = false;
  bool _confirmed = false;
  bool _handedOff = false;

  String get nonce =>
      _state ?? (throw StateError('MAX challenge has not started'));

  Future<void> launchMax() async {
    if (_state != null || _cancelled) {
      throw StateError('MAX challenge already used');
    }
    if (botUsername.isEmpty ||
        !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(botUsername)) {
      throw StateError('Invalid MAX bot username');
    }
    final response = await provider.baseRequest(
      function: 'MaxLoginBegin',
      method: 'POST',
      url: '${provider.serverUri}/Api/Max/Login/Begin',
      params: const {},
    );
    final payload = response?['payload'];
    final state = response?['state'];
    final seconds = response?['expiresIn'];
    if (payload is! String ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(payload) ||
        state is! String ||
        !RegExp(r'^[a-f0-9]{32}\.[a-f0-9]{64}$').hasMatch(state) ||
        !state.startsWith('$payload.') ||
        seconds is! num ||
        seconds <= 0 ||
        seconds > 300) {
      throw StateError('Invalid MAX challenge response');
    }
    _payload = payload;
    _state = state;
    _expires = DateTime.now().add(Duration(seconds: seconds.toInt()));
    if (_cancelled) {
      await cancel();
      return;
    }
    final uri = Uri.https('max.ru', '/$botUsername', {'start': _payload!});
    try {
      if (!await _launcher(uri)) throw StateError('Could not open MAX');
    } catch (_) {
      await cancel();
      rethrow;
    }
  }

  String? get startCommand => _payload == null ? null : '/start $_payload';

  void requestPoll() {
    if (!_cancelled && !_pollWake.isCompleted) _pollWake.complete();
  }

  Future<bool> waitForConfirmation() async {
    if (_state == null) throw StateError('MAX challenge has not started');
    var deadline = DateTime.now().add(timeout);
    if (_expires!.isBefore(deadline)) deadline = _expires!;
    try {
      while (!_cancelled && DateTime.now().isBefore(deadline)) {
        Map<String, dynamic>? response;
        try {
          response = await Future.any<Map<String, dynamic>?>([
            provider.baseRequest(
              function: 'MaxPoll',
              method: 'POST',
              url: '${provider.serverUri}/${provider.authorizationApi}/MaxPoll',
              params: {'state': nonce},
              timeout: deadline.difference(DateTime.now()),
            ),
            _cancelledSignal.future.then((_) => null),
          ]);
        } on NsgApiException catch (error) {
          if (error.error.code != 1 && error.error.code != 2) rethrow;
        }
        if (_cancelled) return false;
        if (response != null) {
          if (response['errorCode'] is! int) {
            throw StateError('Invalid MAX poll response');
          }
          final reply = NsgLoginResponse.fromJson(response);
          if (reply.errorCode == 0 && !reply.isError) {
            _confirmed = true;
            return true;
          }
          if (reply.errorCode != 40400 &&
              reply.errorCode != 1 &&
              reply.errorCode != 2) {
            throw NsgApiException(
              NsgApiError(code: reply.errorCode, message: reply.errorMessage),
            );
          }
        }
        await Future.any<void>([
          Future<void>.delayed(pollInterval),
          _cancelledSignal.future,
          _pollWake.future,
        ]);
        _pollWake = Completer<void>();
      }
      await cancel();
      return false;
    } catch (_) {
      await cancel();
      rethrow;
    }
  }

  String takeConfirmedState() {
    if (!_confirmed || _cancelled || _handedOff) {
      throw StateError('MAX challenge is not confirmed');
    }
    _handedOff = true;
    return nonce;
  }

  Future<void> cancel() async {
    if (_handedOff) return;
    _cancelled = true;
    if (!_cancelledSignal.isCompleted) _cancelledSignal.complete();
    if (_state == null || _cancelSent) return;
    _cancelSent = true;
    try {
      await provider.baseRequest(
        function: 'MaxLoginCancel',
        method: 'POST',
        url: '${provider.serverUri}/Api/Max/Login/Cancel',
        params: {'state': nonce},
        timeout: const Duration(seconds: 5),
      );
    } catch (_) {
      /* The server challenge also has a bounded TTL. */
    }
  }
}
