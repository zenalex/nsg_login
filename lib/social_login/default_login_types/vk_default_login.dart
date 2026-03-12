import 'package:flutter/material.dart';
import 'package:flutter_login_vk/flutter_login_vk.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nsg_controls/nsg_control_options.dart';
import 'package:nsg_data/authorize/nsg_social_login_response.dart';
import 'package:nsg_login/helpers.dart';
import 'package:nsg_login/social_login/default_login_types/default_login_dialog.dart';
import 'package:nsg_login/social_login/social_login_types.dart';

abstract class VkDefaultAuth extends SocialAuthType {
  String get vkAppId;
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
      await SocialLoginDialog.show(
        context,
        builder: (dialogContext) => VkLoginWidget(
          appId: vkAppId,
          title: socialName,
          logo: icon(50),
          buttonText: buttonText,
          onLoginSuccess: (user, accessToken) {
            response = NsgSocialLoginResponse(
              code: accessToken.secret.toString(),
              state: accessToken.token,
              payload: user.toMap()..addAll(accessToken.toMap()),
              loginType: 'Vk',
            );
            Navigator.of(dialogContext).pop();
          },
        ),
      );
    }
    return response;
  }

  @override
  Widget Function(void Function() login) get socialLoginButton =>
      (onSocialTap) => SocialLoginButton(
        onTap: onSocialTap,
        backgroundColor: const Color(0xFF0077FF),
        buttonText: tran.login_via_social(tran.vk),
        textStyle: TextStyle(
          color: nsgtheme.colorBase.c0,
          fontSize: nsgtheme.sizeM,
          fontWeight: FontWeight.w600,
        ),
        logo: icon(20),
      );

  @override
  String get socialName => tran.vk;

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
}

class VkLoginWidget extends StatelessWidget {
  const VkLoginWidget({
    super.key,
    required this.appId,
    required this.buttonText,
    required this.onLoginSuccess,
    this.onAuthError,
    this.title,
    this.logo,
  });

  final String appId;
  final String buttonText;
  final String? title;
  final Widget? logo;
  final void Function(VKUserProfile user, VKAccessToken token) onLoginSuccess;
  final void Function(dynamic error)? onAuthError;

  @override
  Widget build(BuildContext context) {
    return DefaultSocialLoginDialog(
      showPhoneInput: false,
      title: title,
      logo: logo,
      buttonText: buttonText,
      onButtonPressed: (phoneNumber) async {
        final vkLogin = VKLogin();
        await vkLogin.initSdk();
        final res = await vkLogin.logIn(
          scope: [VKScope.email, VKScope.notifications, VKScope.messages],
        );

        if (res.isError) {
          throw Exception('Ошибка VK: ${res.asError!.error}');
        }
        final loginResult = res.asValue!.value;
        if (loginResult.isCanceled) {
          return;
        }
        if (loginResult.accessToken == null) {
          throw Exception('Не удалось получить токен VK');
        }

        final profileRes = await vkLogin.getUserProfile();

        if (profileRes.isError || profileRes.asValue?.value == null) {
          throw Exception('Не удалось загрузить профиль VK');
        }

        final profile = profileRes.asValue!.value!;
        onLoginSuccess(profile, loginResult.accessToken!);
      },
      onAuthError: (error) {
        if (onAuthError != null) {
          onAuthError!(error);
        } else {
          throw error;
        }
      },
    );
  }
}
