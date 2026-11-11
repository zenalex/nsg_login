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
  });

  final bool cancelled;
  final bool pending;
  final bool confirmed;
  final int errorCode;
  final String token;
}

enum MessengerPhoneIntent { access, recovery }

/// Чем закончился диалог. null у showDialog — человек закрыл его сам.
class MessengerPhoneDialogOutcome {
  const MessengerPhoneDialogOutcome.access(this.phone)
    : accessConfirmed = true,
      recoveryMessage = null;

  const MessengerPhoneDialogOutcome.recovery(this.phone, this.recoveryMessage)
    : accessConfirmed = false;

  final bool accessConfirmed;
  final String phone;
  final String? recoveryMessage;
}

bool messengerPhoneUrlAllowed(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return false;
  return uri.host == 't.me' || uri.host == 'max.ru';
}
