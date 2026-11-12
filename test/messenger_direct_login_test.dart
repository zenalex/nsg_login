import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_login/messenger_direct_login.dart';
import 'package:nsg_login/social_login/default_login_types/max_default_login.dart';
import 'package:nsg_login/social_login/default_login_types/telegram_default_login.dart';
import 'package:nsg_login/social_login/social_login_types.dart';

class _Telegram extends TelegramDefaultAuth {
  @override
  String get botId => '1';

  @override
  String get botDomain => 'example.test';

  @override
  String get verifyFunction => 'LoginTelegram';

  @override
  String get verifyMethodName => 'LoginTelegram';
}

class _Max extends MaxDefaultAuth {
  @override
  String get botId => '1';

  @override
  String get botUsername => 'bot';
}

class _Wrapped extends SocialAuthType {
  _Wrapped(this.verifyMethodName);

  @override
  final String verifyMethodName;

  @override
  String get requestFunction => '';

  @override
  String get requestMethodName => '';

  @override
  String get verifyFunction => '';

  @override
  String get socialName => 'wrapped';

  @override
  Widget icon(double size) => const SizedBox.shrink();

  @override
  Widget Function(void Function() login) get socialLoginButton =>
      (_) => const SizedBox.shrink();
}

void main() {
  test(
    'прямой веб-вход берёт канал кнопки, регистрация остаётся с выбором',
    () {
      expect(directMessengerChannel(_Telegram()), 'telegram');
      expect(directMessengerChannel(_Max()), 'max');
      expect(directMessengerChannel(_Wrapped('LoginMax')), 'max');
      expect(directMessengerChannel(_Wrapped('LoginTelegram')), 'telegram');
      expect(directMessengerChannel(_Wrapped('VerifyVK')), isNull);

      bool open(SocialAuthType type, {required bool isWeb}) =>
          opensDirectMessengerDialog(
            type: type,
            isWeb: isWeb,
            messengerReady: true,
          );

      expect(open(_Telegram(), isWeb: true), isTrue);
      expect(open(_Max(), isWeb: true), isTrue);
      expect(open(_Wrapped('LoginMax'), isWeb: true), isTrue);
      expect(open(_Telegram(), isWeb: false), isFalse);
      expect(open(_Max(), isWeb: false), isFalse);
      expect(
        opensDirectMessengerDialog(
          type: _Telegram(),
          isWeb: true,
          messengerReady: false,
        ),
        isFalse,
      );
    },
  );
}
