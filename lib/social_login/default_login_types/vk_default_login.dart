import 'package:flutter/material.dart';
import 'package:flutter_login_vk/flutter_login_vk.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nsg_controls/dialog/nsg_future_progress_exception.dart';
import 'package:nsg_controls/nsg_button.dart';
import 'package:nsg_controls/nsg_control_options.dart';
import 'package:nsg_data/authorize/nsg_social_login_response.dart';
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
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(socialName),
          content: VkLoginWidget(
            appId: vkAppId,
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
        ),
      );
    }
    return response;
  }

  @override
  Widget Function(void Function() login) get icon =>
      (onSocialTap) => SocialLoginButton(
        onTap: onSocialTap,
        backgroundColor: const Color(0xFF0077FF),
        buttonText: 'Sign in with Vk',
        textStyle: TextStyle(
          color: nsgtheme.colorBase.c0,
          fontSize: nsgtheme.sizeM,
          fontWeight: FontWeight.w600,
        ),
        logo: SvgPicture.string(
          '''<svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M0 48C0 25.3726 0 14.0589 7.02944 7.02944C14.0589 0 25.3726 0 48 0H52C74.6274 0 85.9411 0 92.9706 7.02944C100 14.0589 100 25.3726 100 48V52C100 74.6274 100 85.9411 92.9706 92.9706C85.9411 100 74.6274 100 52 100H48C25.3726 100 14.0589 100 7.02944 92.9706C0 85.9411 0 74.6274 0 52V48Z" fill="#0077FF"/>
                <path d="M53.2083 72.042C30.4167 72.042 17.4168 56.417 16.8751 30.417H28.2917C28.6667 49.5003 37.0833 57.5836 43.7499 59.2503V30.417H54.5002V46.8752C61.0836 46.1669 67.9994 38.667 70.3328 30.417H81.0831C79.2914 40.5837 71.7914 48.0836 66.458 51.1669C71.7914 53.6669 80.3335 60.2086 83.5835 72.042H71.7498C69.2081 64.1253 62.8752 58.0003 54.5002 57.1669V72.042H53.2083Z" fill="white"/>
                </svg>''',
          semanticsLabel: 'VK logo',
          width: 20,
          height: 20,
        ),
      );

  @override
  String get socialName => "Vk";
}

class VkLoginWidget extends StatelessWidget {
  const VkLoginWidget({
    super.key,
    required this.appId,
    required this.buttonText,
    required this.onLoginSuccess,
    this.onAuthError,
  });

  final String appId;

  final String buttonText;

  final void Function(VKUserProfile user, VKAccessToken token) onLoginSuccess;
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
                try {
                  final vkLogin = VKLogin();
                  await vkLogin.initSdk();
                  final res = await vkLogin.logIn(
                    scope: [
                      VKScope.email,
                      VKScope.notifications,
                      VKScope.messages,
                    ],
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
                } finally {}
              },
            );
          },
        ),
      ],
    );
  }
}
