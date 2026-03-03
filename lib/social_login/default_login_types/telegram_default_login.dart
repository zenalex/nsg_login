import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nsg_controls/nsg_controls.dart';
import 'package:nsg_data/authorize/nsg_social_login_response.dart';
import 'package:nsg_login/social_login/social_login_types.dart';
import 'package:telegram_login_flutter/telegram_login_flutter.dart';

abstract class TelegramDefaultAuth extends SocialAuthType {
  String get botId;
  String get botDomain;
  String get buttonText;

  @override
  String get requestFunction => "";

  @override
  String get requestMethodName => "";

  @override
  String get verifyFunction;

  @override
  String get verifyMethodName;

  @override
  bool get useNativeAuth => true;

  @override
  Future<NsgSocialLoginResponse?> performNativeAuth({
    BuildContext? context,
  }) async {
    NsgSocialLoginResponse? response;
    if (context != null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(socialName),
          content: TelegramLoginWidget(
            botId: botId,
            botDomain: botDomain,
            buttonText: buttonText,
            onLoginSuccess: (user) {
              response = NsgSocialLoginResponse(
                code: user.hash.toString(),
                state: user.id.toString(),
                payload: user.toJson(),
                loginType: 'Telegram',
              );
              Navigator.of(dialogContext).pop();
            },
          ),
        ),
      );
    }
    return response;
  }

  @override
  Widget Function(void Function() login) get icon =>
      (onSocialTap) => InkWell(
        onTap: onSocialTap,
        child: SvgPicture.string(
          '''<svg version="1.2" baseProfile="tiny" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
	 x="0px" y="0px" viewBox="0 0 100 100" overflow="visible" xml:space="preserve">
	<path fill="#FFFFFF" d="M10.6,54.3c-0.2-7.4,1.4-14.1,5.9-20c5-6.5,11.7-9.8,19.9-9.3c2.7,0.1,5.3,1,7.6,2.2
		c4.5,2.3,8.7,2.2,13.2,0c3.6-1.8,7.6-2.8,11.7-2.6c7,0.4,12.9,3,17.3,8.5c0.7,0.9,0.7,1.3-0.3,2c-5.1,3.5-8.4,8.4-9.1,14.5
		c-1.3,9.8,2.8,17.7,11.8,22.5c0.7,0.4,1.1,0.6,0.8,1.4C86.4,82,82,89.4,75.6,95.4c-3.8,3.6-8.4,4.1-13.2,2.1
		c-3.4-1.4-6.6-2.9-10.4-2.8c-3.3,0-6.3,0.9-9.3,2.3c-2,0.9-4,1.6-6.2,1.7c-3.3,0.2-6.1-1-8.3-3.3C21,88.4,16,80,13,70.4
		C11.4,65.1,10.4,59.8,10.6,54.3z"/>
	<path fill="#FFFFFF" d="M49.7,20C50.5,13.7,54,8,60.4,4.1c2.5-1.5,5.1-2.6,8-2.8c0.8-0.1,1,0.1,1.1,0.9c0.5,9.5-6.6,19.1-15.9,21.2
		c-0.4,0.1-0.8,0.1-1.2,0.2C49.7,23.8,49.7,23.8,49.7,20z"/>
</svg>''',
          semanticsLabel: 'Telegram logo',
          width: 40,
          height: 40,
        ),
      );

  @override
  String get socialName => "Telegram";
}

class TelegramLoginWidget extends StatelessWidget {
  const TelegramLoginWidget({
    super.key,
    required this.botId,
    required this.botDomain,
    this.timeout,
    required this.buttonText,
    required this.onLoginSuccess,
    this.onAuthError,
  });

  final String botId;
  final String botDomain;
  final String buttonText;
  final Duration? timeout;
  final void Function(TelegramUser user) onLoginSuccess;
  final void Function(dynamic error)? onAuthError;

  @override
  Widget build(BuildContext context) {
    var phoneController = TextEditingController();
    return Column(
      children: [
        TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Номер телефона (международный формат)',
            hintText: '+79001234567',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          autocorrect: false,
        ),
        const SizedBox(height: 24),
        NsgButton(
          text: buttonText,
          onTap: () async {
            await nsgFutureProgressAndException(
              func: () async {
                var localTimeout = timeout ?? const Duration(minutes: 1);
                try {
                  final telegramAuth = TelegramAuth(
                    phoneNumber: phoneController.text,
                    botId: botId,
                    botDomain: botDomain,
                    timeout: localTimeout,
                  );

                  await telegramAuth.launchTelegram();
                  await telegramAuth.initiateLogin();

                  final startTime = DateTime.now();
                  bool isLoggedIn = false;
                  TelegramUser? user;

                  while (DateTime.now().difference(startTime) < localTimeout) {
                    isLoggedIn = await telegramAuth.checkLoginStatus();
                    if (isLoggedIn) {
                      user = await telegramAuth.getUserData();
                      break;
                    }
                    await Future.delayed(const Duration(seconds: 2));
                  }
                  if (isLoggedIn && user != null) {
                    onLoginSuccess(user);
                  } else {
                    throw Exception('Login timeout');
                  }
                } catch (e) {
                  if (onAuthError != null) {
                    onAuthError!(e);
                  } else {
                    rethrow;
                  }
                } finally {}
              },
            );
          },
        ),
      ],
    );
  }
}
