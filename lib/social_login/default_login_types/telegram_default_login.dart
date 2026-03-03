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
      (onSocialTap) => SocialLoginButton(
        onTap: onSocialTap,
        backgroundColor: nsgtheme.colorBase.c100,
        buttonText: 'Sign in with Telegram',
        textStyle: TextStyle(
          color: nsgtheme.colorBase.c0,
          fontSize: nsgtheme.sizeM,
          fontWeight: FontWeight.w600,
        ),
        logo: SvgPicture.string(
          '''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 240.1 240.1">
<linearGradient id="Oval_1_" gradientUnits="userSpaceOnUse" x1="-838.041" y1="660.581" x2="-838.041" y2="660.3427" gradientTransform="matrix(1000 0 0 -1000 838161 660581)">
 <stop offset="0" style="stop-color:#2AABEE"/>
 <stop offset="1" style="stop-color:#229ED9"/>
</linearGradient>
<circle fill-rule="evenodd" clip-rule="evenodd" fill="url(#Oval_1_)" cx="120.1" cy="120.1" r="120.1"/>
<path fill-rule="evenodd" clip-rule="evenodd" fill="#FFFFFF" d="M54.3,118.8c35-15.2,58.3-25.3,70-30.2 c33.3-13.9,40.3-16.3,44.8-16.4c1,0,3.2,0.2,4.7,1.4c1.2,1,1.5,2.3,1.7,3.3s0.4,3.1,0.2,4.7c-1.8,19-9.6,65.1-13.6,86.3 c-1.7,9-5,12-8.2,12.3c-7,0.6-12.3-4.6-19-9c-10.6-6.9-16.5-11.2-26.8-18c-11.9-7.8-4.2-12.1,2.6-19.1c1.8-1.8,32.5-29.8,33.1-32.3 c0.1-0.3,0.1-1.5-0.6-2.1c-0.7-0.6-1.7-0.4-2.5-0.2c-1.1,0.2-17.9,11.4-50.6,33.5c-4.8,3.3-9.1,4.9-13,4.8 c-4.3-0.1-12.5-2.4-18.7-4.4c-7.5-2.4-13.5-3.7-13-7.9C45.7,123.3,48.7,121.1,54.3,118.8z"/>
</svg>''',
          semanticsLabel: 'Telegram logo',
          width: 20,
          height: 20,
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
