/// Куда вести кнопку «Войти через Telegram».
/// В вебе опрос oauth.telegram.org с чужой cookie не работает.
/// Если колбэки бота #4376 есть — тот же диалог. Если нет — кнопку прячем.
enum TelegramLoginRoute { oauthApp, messengerBot, hidden }

TelegramLoginRoute routeTelegramLogin({
  required bool isWeb,
  required bool messengerReady,
}) {
  if (!isWeb) return TelegramLoginRoute.oauthApp;
  if (messengerReady) return TelegramLoginRoute.messengerBot;
  return TelegramLoginRoute.hidden;
}

/// Дольше минуты: опрос бота #4376 ждёт пять минут.
const telegramOauthActiveTimeout = Duration(minutes: 5);

/// Активное время ожидания oauth. Пока приложение на паузе, таймаут не идёт.
class TelegramOauthWait {
  TelegramOauthWait({required this.timeout, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Duration timeout;
  final DateTime Function() _now;
  Duration _active = Duration.zero;
  DateTime? _mark;
  bool paused = false;
  bool wake = false;

  Duration get active => _active;
  bool get expired => _active >= timeout;

  void advance() {
    final now = _now();
    final mark = _mark;
    if (mark != null && !paused) {
      final gap = now.difference(mark);
      if (!gap.isNegative && gap > Duration.zero) {
        _active += gap;
      }
    }
    _mark = now;
  }

  void notePause() {
    advance();
    paused = true;
  }

  void noteResume() {
    advance();
    paused = false;
    wake = true;
  }
}

/// null — активное время вышло. Ошибка проверки пробрасывается.
/// [wake] обрывает сон, чтобы сразу проверить статус после возврата.
Future<T?> waitTelegramOauth<T>({
  required TelegramOauthWait wait,
  required Future<bool> Function() isLoggedIn,
  required Future<T?> Function() readUser,
  required Future<void> Function(Duration step) delay,
  Duration interval = const Duration(seconds: 2),
  bool Function()? cancelled,
  Duration slice = const Duration(milliseconds: 200),
}) async {
  while (true) {
    if (cancelled?.call() == true) return null;
    wait.advance();
    if (wait.expired) return null;
    wait.wake = false;
    if (await isLoggedIn()) {
      return readUser();
    }
    var slept = Duration.zero;
    while (slept < interval) {
      if (wait.wake || cancelled?.call() == true) break;
      wait.advance();
      if (wait.expired) return null;
      final left = interval - slept;
      final step = left < slice ? left : slice;
      await delay(step);
      slept += step;
    }
  }
}
