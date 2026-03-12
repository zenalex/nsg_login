import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:nsg_controls/nsg_controls.dart';
import 'package:nsg_data/authorize/nsg_social_login_response.dart';
import 'package:nsg_login/helpers.dart';
import 'package:nsg_login/social_login/social_login_types.dart';
import 'package:telegram_login_flutter/telegram_login_flutter.dart';

abstract class TelegramDefaultAuth extends SocialAuthType {
  String get botId;
  String get botDomain;

  String get buttonText => tran.login_via_social("Telegram");
  TextStyle? get textStyle => null;
  Color? get backgroundColor => null;

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
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: TelegramLoginWidget(
            title: socialName,
            botId: botId,
            botDomain: botDomain,
            buttonText: buttonText,
            logo: icon(50),
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
  Widget Function(void Function() login) get socialLoginButton =>
      (onSocialTap) => SocialLoginButton(
        onTap: onSocialTap,
        backgroundColor: backgroundColor,
        buttonText: buttonText,
        textStyle: textStyle,
        logo: icon(20),
      );

  @override
  Widget icon(size) => SvgPicture.string(
    '''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 240.1 240.1">
<linearGradient id="Oval_1_" gradientUnits="userSpaceOnUse" x1="-838.041" y1="660.581" x2="-838.041" y2="660.3427" gradientTransform="matrix(1000 0 0 -1000 838161 660581)">
 <stop offset="0" style="stop-color:#2AABEE"/>
 <stop offset="1" style="stop-color:#229ED9"/>
</linearGradient>
<circle fill-rule="evenodd" clip-rule="evenodd" fill="url(#Oval_1_)" cx="120.1" cy="120.1" r="120.1"/>
<path fill-rule="evenodd" clip-rule="evenodd" fill="#FFFFFF" d="M54.3,118.8c35-15.2,58.3-25.3,70-30.2 c33.3-13.9,40.3-16.3,44.8-16.4c1,0,3.2,0.2,4.7,1.4c1.2,1,1.5,2.3,1.7,3.3s0.4,3.1,0.2,4.7c-1.8,19-9.6,65.1-13.6,86.3 c-1.7,9-5,12-8.2,12.3c-7,0.6-12.3-4.6-19-9c-10.6-6.9-16.5-11.2-26.8-18c-11.9-7.8-4.2-12.1,2.6-19.1c1.8-1.8,32.5-29.8,33.1-32.3 c0.1-0.3,0.1-1.5-0.6-2.1c-0.7-0.6-1.7-0.4-2.5-0.2c-1.1,0.2-17.9,11.4-50.6,33.5c-4.8,3.3-9.1,4.9-13,4.8 c-4.3-0.1-12.5-2.4-18.7-4.4c-7.5-2.4-13.5-3.7-13-7.9C45.7,123.3,48.7,121.1,54.3,118.8z"/>
</svg>''',
    semanticsLabel: 'Telegram logo',
    width: size,
    height: size,
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
    this.title,
    this.logo,
  });

  final String botId;
  final String botDomain;
  final String buttonText;
  final String? title;
  final Duration? timeout;
  final Widget? logo;
  final void Function(TelegramUser user) onLoginSuccess;
  final void Function(dynamic error)? onAuthError;

  @override
  Widget build(BuildContext context) {
    final phoneController = TextEditingController();
    final inputDecoration = InputDecoration(
      contentPadding: const EdgeInsets.all(10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(nsgtheme.borderRadius),
        borderSide: BorderSide(color: nsgtheme.colorTertiary, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(nsgtheme.borderRadius),
        borderSide: BorderSide(color: nsgtheme.colorTertiary, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(nsgtheme.borderRadius),
        borderSide: BorderSide(color: nsgtheme.colorText, width: 1.0),
      ),
      filled: true,
      fillColor: nsgtheme.colorBase.b0,
      errorStyle: const TextStyle(fontSize: 12),
      hintStyle: TextStyle(color: nsgtheme.colorText.withAlpha(75)),
    );

    return Container(
      decoration: BoxDecoration(
        color: nsgtheme.colorMainBack,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (logo == null) Text(title ?? "Telegram"),
              const Expanded(child: SizedBox()),
              InkWell(
                child: const Icon(Icons.close),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          if (logo != null)
            Padding(
              padding: const EdgeInsetsGeometry.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [logo!],
              ),
            ),
          Text(
            tran.enter_your_phone_number,
            style: TextStyle(color: nsgtheme.colorText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phoneController,
            cursorColor: Theme.of(context).primaryColor,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            style: TextStyle(color: nsgtheme.colorText),
            textAlign: TextAlign.center,
            decoration: inputDecoration.copyWith(
              hintText: tran.phone_number_in_international_format,
            ),
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
          const SizedBox(height: 16),
          NsgButton(
            margin: const EdgeInsets.only(top: 4),
            text: buttonText,
            onPressed: () async {
              await nsgFutureProgressAndException(
                func: () async {
                  final localTimeout = timeout ?? const Duration(minutes: 1);
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
                    var isLoggedIn = false;
                    TelegramUser? user;

                    while (DateTime.now().difference(startTime) <
                        localTimeout) {
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
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
