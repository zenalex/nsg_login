/// Результат Begin. [ok] только когда есть и адрес бота, и payload.
class MessengerPhoneBeginResult {
  const MessengerPhoneBeginResult({
    this.errorCode = 0,
    this.url = '',
    this.payload = '',
  });

  final int errorCode;
  final String url;
  final String payload;

  bool get ok => errorCode == 0 && url.isNotEmpty && payload.isNotEmpty;
}

/// Один законченный опрос. [cancelled] — человек выбрал другой мессенджер
/// или закрыл диалог; токен в этом случае применять нельзя.
class MessengerPhonePollResult {
  const MessengerPhonePollResult({
    this.cancelled = false,
    this.pending = false,
    this.confirmed = false,
    this.errorCode = 0,
    this.token = '',
    this.passwordState = '',
  });

  final bool cancelled;
  final bool pending;
  final bool confirmed;
  final int errorCode;
  final String token;

  /// required — новая учётка, пароль обязателен.
  /// missing — пароль пуст, напоминание можно отложить.
  /// Пусто и set — сразу в приложение. В анонимный ответ не приходит.
  final String passwordState;
}

enum MessengerPasswordStep { enterApp, requirePassword, offerPassword }

MessengerPasswordStep messengerPasswordStep(String? state) {
  switch (state) {
    case 'required':
      return MessengerPasswordStep.requirePassword;
    case 'missing':
      return MessengerPasswordStep.offerPassword;
    default:
      return MessengerPasswordStep.enterApp;
  }
}

enum MessengerPhoneIntent { access, recovery }

/// Ответ восстановления. Сообщение одно и то же, есть учётка или нет.
/// [url] — ссылка на бота, если сервер её прислал. Пустая ссылка не ветвит экран.
class MessengerPhoneRecoveryResult {
  const MessengerPhoneRecoveryResult(this.message, {this.url});

  final String message;
  final String? url;
}

/// Чем закончился диалог. null у showDialog — человек закрыл его сам.
class MessengerPhoneDialogOutcome {
  const MessengerPhoneDialogOutcome.access(this.phone, {this.passwordState})
    : accessConfirmed = true,
      recoveryMessage = null;

  const MessengerPhoneDialogOutcome.recovery(this.phone, this.recoveryMessage)
    : accessConfirmed = false,
      passwordState = null;

  final bool accessConfirmed;
  final String phone;
  final String? recoveryMessage;
  final String? passwordState;
}

bool messengerPhoneUrlAllowed(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return false;
  return uri.host == 't.me' || uri.host == 'max.ru';
}
