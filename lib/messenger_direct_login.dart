import 'package:nsg_login/social_login/default_login_types/max_default_login.dart';
import 'package:nsg_login/social_login/default_login_types/telegram_default_login.dart';
import 'package:nsg_login/social_login/default_login_types/telegram_oauth_wait.dart';
import 'package:nsg_login/social_login/social_login_types.dart';

/// Канал прямого входа. Обёртка аналитики тип прячет, но verifyMethodName
/// оставляет: LoginTelegram / LoginMax.
String? directMessengerChannel(SocialAuthType type) {
  if (type is TelegramDefaultAuth) return 'telegram';
  if (type is MaxDefaultAuth) return 'max';
  switch (type.verifyMethodName) {
    case 'LoginTelegram':
      return 'telegram';
    case 'LoginMax':
      return 'max';
  }
  return null;
}

/// Кнопка «Войти через Telegram/MAX» уже выбрала канал.
/// Диалог бота без повторного вопроса. Регистрация и восстановление сюда не входят.
bool opensDirectMessengerDialog({
  required SocialAuthType type,
  required bool isWeb,
  required bool messengerReady,
}) {
  if (!isWeb || !messengerReady) return false;
  final channel = directMessengerChannel(type);
  if (channel == 'telegram') {
    return routeTelegramLogin(isWeb: true, messengerReady: true) ==
        TelegramLoginRoute.messengerBot;
  }
  return channel == 'max';
}
